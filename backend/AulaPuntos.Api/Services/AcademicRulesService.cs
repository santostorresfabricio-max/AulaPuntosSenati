using AulaPuntos.Api.Contracts;
using AulaPuntos.Api.Data;
using AulaPuntos.Api.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AulaPuntos.Api.Services;

/// <summary>Error de regla de negocio: la operación es inválida y NO debe reintentarse.</summary>
public class BusinessRuleException(string message) : Exception(message);

public enum ApplyResult
{
    Applied,      // se insertó / actualizó
    Duplicate,    // ya existía (reintento idempotente)
    SkippedOlder  // el servidor tiene un dato más reciente (last-write-wins)
}

/// <summary>
/// Reglas de negocio compartidas por los endpoints directos (online) y por /api/sync (offline).
/// Los métodos NO llaman SaveChanges: el llamador decide la unidad de trabajo.
/// </summary>
public class AcademicRulesService(AulaPuntosDbContext db)
{
    // ------------------------------------------------------------------ Lectura
    public async Task<IReadOnlyList<GrupoDto>> GetGruposDeInstructorAsync(Guid instructorId, CancellationToken ct)
    {
        var grupos = await db.Grupos
            .AsNoTracking()
            .Where(g => g.InstructorId == instructorId)
            .Include(g => g.Matriculas).ThenInclude(m => m.Estudiante)
            .Include(g => g.Sesiones)
            .OrderBy(g => g.Codigo)
            .ToListAsync(ct);

        return grupos.Select(g => new GrupoDto(
            g.GrupoId, g.Codigo, g.Nombre, g.Periodo, g.InstructorId,
            g.Matriculas
                .Where(m => m.Estudiante!.Estado == EstadoRegistro.Activo)
                .Select(m => m.Estudiante!)
                .OrderBy(e => e.Apellidos)
                .Select(e => new EstudianteDto(e.EstudianteId, e.CodigoInstitucional, e.Nombres, e.Apellidos, e.Estado.ToString()))
                .ToList(),
            g.Sesiones
                .Where(s => s.Estado != EstadoSesion.Anulada)
                .OrderBy(s => s.Numero)
                .Select(s => new SesionDto(s.SesionId, s.GrupoId, s.Numero, s.Fecha, s.Tema, s.Tipo, s.Estado.ToString()))
                .ToList()
        )).ToList();
    }

    public async Task<IReadOnlyList<ActividadDto>> GetActividadesAsync(CancellationToken ct) =>
        await db.Actividades.AsNoTracking().Where(a => a.Activa)
            .OrderBy(a => a.Nombre)
            .Select(a => new ActividadDto(a.ActividadId, a.Nombre))
            .ToListAsync(ct);

    // ------------------------------------------------------------------ Sesiones
    public async Task<ApplyResult> UpsertSesionAsync(Guid instructorId, CrearSesionRequest req, DateTime clientTimestamp, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(req.Tema))
            throw new BusinessRuleException("El tema de la sesión es obligatorio.");

        var grupoEsDelInstructor = await db.Grupos.AnyAsync(g => g.GrupoId == req.GrupoId && g.InstructorId == instructorId, ct);
        if (!grupoEsDelInstructor)
            throw new BusinessRuleException($"El grupo {req.GrupoId} no existe o no pertenece al instructor.");

        var existente = await db.Sesiones.FirstOrDefaultAsync(s => s.SesionId == req.SesionId, ct);
        if (existente is null)
        {
            // El número de sesión lo asigna SIEMPRE el servidor para evitar choques entre dispositivos.
            var siguienteNumero = (await db.Sesiones.Where(s => s.GrupoId == req.GrupoId)
                .MaxAsync(s => (int?)s.Numero, ct) ?? 0) + 1;

            db.Sesiones.Add(new Sesion
            {
                SesionId = req.SesionId,
                GrupoId = req.GrupoId,
                Numero = siguienteNumero,
                Fecha = req.Fecha,
                Tema = req.Tema.Trim(),
                Tipo = string.IsNullOrWhiteSpace(req.Tipo) ? "Teoria" : req.Tipo,
                ActualizadoEnUtc = clientTimestamp
            });
            return ApplyResult.Applied;
        }

        if (existente.GrupoId != req.GrupoId)
            throw new BusinessRuleException("No se puede mover una sesión a otro grupo.");

        if (existente.ActualizadoEnUtc >= clientTimestamp)
            return ApplyResult.SkippedOlder;

        existente.Fecha = req.Fecha;
        existente.Tema = req.Tema.Trim();
        existente.Tipo = string.IsNullOrWhiteSpace(req.Tipo) ? existente.Tipo : req.Tipo;
        existente.ActualizadoEnUtc = clientTimestamp;
        return ApplyResult.Applied;
    }

    // ------------------------------------------------------------------ Asistencia
    public static EstadoAsistencia ParseEstado(string? estado)
    {
        // Solo se aceptan los nombres exactos (sin valores numéricos) -> presente, tardanza, falta, justificado
        if (string.IsNullOrWhiteSpace(estado) || estado.Any(char.IsDigit) ||
            !Enum.TryParse<EstadoAsistencia>(estado.Trim(), ignoreCase: true, out var parsed) ||
            !Enum.IsDefined(parsed))
        {
            throw new BusinessRuleException(
                $"Estado de asistencia '{estado}' no permitido. Valores válidos: presente, tardanza, falta, justificado.");
        }
        return parsed;
    }

    public async Task<ApplyResult> UpsertAsistenciaAsync(Guid instructorId, RegistrarAsistenciaRequest req, CancellationToken ct)
    {
        var estado = ParseEstado(req.Estado);
        await ValidarSesionYEstudianteAsync(instructorId, req.SesionId, req.EstudianteId, ct);

        var fechaRegistro = req.FechaRegistro == default ? DateTime.UtcNow : req.FechaRegistro.ToUniversalTime();

        // Clave natural: (SesionId, EstudianteId). Si el dispositivo genera otro AsistenciaId para el
        // mismo alumno/sesión, se actualiza el registro existente en vez de duplicarlo.
        var existente = await db.Asistencias
            .FirstOrDefaultAsync(a => a.SesionId == req.SesionId && a.EstudianteId == req.EstudianteId, ct);

        if (existente is null)
        {
            db.Asistencias.Add(new Asistencia
            {
                AsistenciaId = req.AsistenciaId,
                SesionId = req.SesionId,
                EstudianteId = req.EstudianteId,
                Estado = estado,
                FechaRegistro = fechaRegistro,
                SincronizadoEnUtc = DateTime.UtcNow
            });
            return ApplyResult.Applied;
        }

        // Last-write-wins: un cambio offline antiguo NO sobrescribe una marca más reciente.
        if (existente.FechaRegistro >= fechaRegistro)
            return existente.Estado == estado ? ApplyResult.Duplicate : ApplyResult.SkippedOlder;

        existente.Estado = estado;
        existente.FechaRegistro = fechaRegistro;
        existente.SincronizadoEnUtc = DateTime.UtcNow;
        return ApplyResult.Applied;
    }

    // ------------------------------------------------------------------ Participación
    public async Task<ApplyResult> RegistrarParticipacionAsync(Guid instructorId, RegistrarParticipacionRequest req, CancellationToken ct)
    {
        if (req.Puntos == 0 || req.Puntos < -5 || req.Puntos > 5)
            throw new BusinessRuleException("Los puntos deben estar entre -5 y 5 y ser distintos de 0.");

        // Idempotencia: el ParticipacionId lo genera el cliente una sola vez por toque (+1, +2, -1).
        // Si el reintento llega de nuevo, el registro ya existe y NO se vuelve a sumar.
        var yaExiste = await db.Participaciones.AnyAsync(p => p.ParticipacionId == req.ParticipacionId, ct)
                       || db.Participaciones.Local.Any(p => p.ParticipacionId == req.ParticipacionId);
        if (yaExiste)
            return ApplyResult.Duplicate;

        await ValidarSesionYEstudianteAsync(instructorId, req.SesionId, req.EstudianteId, ct);

        var actividadValida = await db.Actividades.AnyAsync(a => a.ActividadId == req.ActividadId && a.Activa, ct);
        if (!actividadValida)
            throw new BusinessRuleException($"La actividad {req.ActividadId} no existe o está inactiva.");

        db.Participaciones.Add(new Participacion
        {
            ParticipacionId = req.ParticipacionId,
            SesionId = req.SesionId,
            EstudianteId = req.EstudianteId,
            ActividadId = req.ActividadId,
            Puntos = req.Puntos,
            Fecha = req.Fecha == default ? DateTime.UtcNow : req.Fecha.ToUniversalTime(),
            SincronizadoEnUtc = DateTime.UtcNow
        });
        return ApplyResult.Applied;
    }

    // ------------------------------------------------------------------ Validaciones comunes
    private async Task ValidarSesionYEstudianteAsync(Guid instructorId, Guid sesionId, Guid estudianteId, CancellationToken ct)
    {
        var sesion = await db.Sesiones
            .Where(s => s.SesionId == sesionId)
            .Select(s => new { s.GrupoId, s.Estado, s.Grupo!.InstructorId })
            .FirstOrDefaultAsync(ct);

        if (sesion is null)
            throw new BusinessRuleException($"La sesión {sesionId} no existe en el servidor.");
        if (sesion.InstructorId != instructorId)
            throw new BusinessRuleException("La sesión no pertenece a un grupo del instructor.");
        if (sesion.Estado == EstadoSesion.Anulada)
            throw new BusinessRuleException("No se pueden registrar datos en una sesión anulada.");

        var matriculado = await db.Matriculas.AnyAsync(m => m.GrupoId == sesion.GrupoId && m.EstudianteId == estudianteId, ct);
        if (!matriculado)
            throw new BusinessRuleException($"El estudiante {estudianteId} no está matriculado en el grupo de la sesión.");
    }
}
