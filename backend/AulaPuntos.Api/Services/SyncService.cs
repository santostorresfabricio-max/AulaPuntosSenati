using System.Text.Json;
using AulaPuntos.Api.Contracts;
using AulaPuntos.Api.Data;
using AulaPuntos.Api.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AulaPuntos.Api.Services;

/// <summary>
/// Procesa el lote de operaciones encoladas offline en el dispositivo.
/// Cada operación se aplica en su propia transacción junto con su registro en
/// OperacionesSincronizadas, de modo que un reintento del mismo lote es idempotente.
/// </summary>
public class SyncService(AulaPuntosDbContext db, AcademicRulesService rules, ILogger<SyncService> logger)
{
    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);

    // Orden de dependencia: primero las sesiones (pueden haberse creado offline),
    // luego asistencias y participaciones que las referencian.
    private static int Prioridad(string entityType) => entityType switch
    {
        SyncEntityTypes.Sesion => 0,
        SyncEntityTypes.Asistencia => 1,
        SyncEntityTypes.Participacion => 2,
        _ => 9
    };

    public async Task<SyncResponse> ProcessAsync(SyncRequest request, CancellationToken ct)
    {
        var instructorActivo = await db.Instructores
            .AnyAsync(i => i.InstructorId == request.InstructorId && i.Estado == EstadoRegistro.Activo, ct);
        if (!instructorActivo)
            throw new BusinessRuleException("Instructor no válido o inactivo.");

        var processed = new List<Guid>();
        var duplicates = new List<Guid>();
        var skipped = new List<Guid>();
        var rejected = new List<SyncRejectedDto>();

        var operaciones = request.Operations
            .OrderBy(o => Prioridad(o.EntityType?.ToLowerInvariant() ?? string.Empty))
            .ThenBy(o => o.ClientTimestamp)
            .ToList();

        // Operaciones ya procesadas en envíos anteriores (reintentos por timeout, pérdida de señal, etc.)
        var ids = operaciones.Select(o => o.OperationId).ToList();
        var yaProcesadas = (await db.OperacionesSincronizadas
            .Where(o => ids.Contains(o.OperationId))
            .Select(o => o.OperationId)
            .ToListAsync(ct)).ToHashSet();

        foreach (var op in operaciones)
        {
            if (yaProcesadas.Contains(op.OperationId))
            {
                duplicates.Add(op.OperationId);
                continue;
            }

            var tipo = op.EntityType?.Trim().ToLowerInvariant() ?? string.Empty;
            await using var tx = await db.Database.BeginTransactionAsync(ct);
            try
            {
                var resultado = await ApplyOperationAsync(request.InstructorId, tipo, op, ct);

                db.OperacionesSincronizadas.Add(new OperacionSincronizada
                {
                    OperationId = op.OperationId,
                    TipoEntidad = tipo,
                    DeviceId = request.DeviceId,
                    InstructorId = request.InstructorId,
                    ProcesadoEnUtc = DateTime.UtcNow
                });

                await db.SaveChangesAsync(ct);
                await tx.CommitAsync(ct);
                yaProcesadas.Add(op.OperationId);

                switch (resultado)
                {
                    case ApplyResult.Applied: processed.Add(op.OperationId); break;
                    case ApplyResult.Duplicate: duplicates.Add(op.OperationId); break;
                    case ApplyResult.SkippedOlder: skipped.Add(op.OperationId); break;
                }
            }
            catch (Exception ex) when (ex is BusinessRuleException or JsonException)
            {
                await tx.RollbackAsync(ct);
                db.ChangeTracker.Clear();
                rejected.Add(new SyncRejectedDto(op.OperationId, ex.Message));
            }
            catch (DbUpdateException ex)
            {
                // Conflicto de concurrencia (p. ej. otro dispositivo insertó la misma clave al mismo tiempo).
                // No se marca como procesada: el cliente la conservará y la reintentará.
                await tx.RollbackAsync(ct);
                db.ChangeTracker.Clear();
                logger.LogWarning(ex, "Conflicto al sincronizar la operación {OperationId}", op.OperationId);
            }
        }

        return new SyncResponse(processed, duplicates, skipped, rejected, DateTime.UtcNow);
    }

    private async Task<ApplyResult> ApplyOperationAsync(Guid instructorId, string tipo, SyncOperationDto op, CancellationToken ct)
    {
        if (!string.Equals(op.Action, "upsert", StringComparison.OrdinalIgnoreCase))
            throw new BusinessRuleException($"Acción '{op.Action}' no soportada.");

        var clientTs = op.ClientTimestamp == default ? DateTime.UtcNow : op.ClientTimestamp.ToUniversalTime();

        switch (tipo)
        {
            case SyncEntityTypes.Sesion:
                var sesion = Deserialize<CrearSesionRequest>(op.Payload);
                return await rules.UpsertSesionAsync(instructorId, sesion, clientTs, ct);

            case SyncEntityTypes.Asistencia:
                var asistencia = Deserialize<RegistrarAsistenciaRequest>(op.Payload);
                if (asistencia.FechaRegistro == default)
                    asistencia = asistencia with { FechaRegistro = clientTs };
                return await rules.UpsertAsistenciaAsync(instructorId, asistencia, ct);

            case SyncEntityTypes.Participacion:
                var participacion = Deserialize<RegistrarParticipacionRequest>(op.Payload);
                if (participacion.Fecha == default)
                    participacion = participacion with { Fecha = clientTs };
                return await rules.RegistrarParticipacionAsync(instructorId, participacion, ct);

            default:
                throw new BusinessRuleException($"Tipo de entidad '{op.EntityType}' no soportado.");
        }
    }

    private static T Deserialize<T>(JsonElement payload) =>
        payload.Deserialize<T>(JsonOpts) ?? throw new BusinessRuleException("Payload vacío o inválido.");
}
