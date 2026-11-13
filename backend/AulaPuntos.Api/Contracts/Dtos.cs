using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace AulaPuntos.Api.Contracts;

// ===================== Lectura (catálogos para la app) =====================

public record EstudianteDto(Guid EstudianteId, string CodigoInstitucional, string Nombres, string Apellidos, string Estado);

public record SesionDto(Guid SesionId, Guid GrupoId, int Numero, DateTime Fecha, string Tema, string Tipo, string Estado);

public record GrupoDto(Guid GrupoId, string Codigo, string Nombre, string Periodo, Guid InstructorId,
    IReadOnlyList<EstudianteDto> Estudiantes, IReadOnlyList<SesionDto> Sesiones);

public record ActividadDto(Guid ActividadId, string Nombre);

// ===================== Escritura directa (modo online) =====================

public record RegistrarAsistenciaRequest(
    [property: Required] Guid AsistenciaId,
    [property: Required] Guid SesionId,
    [property: Required] Guid EstudianteId,
    [property: Required] string Estado,             // presente | tardanza | falta | justificado
    DateTime FechaRegistro);

public record RegistrarParticipacionRequest(
    [property: Required] Guid ParticipacionId,      // UUID generado por el cliente = idempotency key
    [property: Required] Guid SesionId,
    [property: Required] Guid EstudianteId,
    [property: Required] Guid ActividadId,
    [property: Range(-5, 5)] int Puntos,
    DateTime Fecha);

public record CrearSesionRequest(
    [property: Required] Guid SesionId,
    [property: Required] Guid GrupoId,
    DateTime Fecha,
    [property: Required, MaxLength(300)] string Tema,
    string Tipo);

// ===================== Sincronización (POST /api/sync) =====================

public static class SyncEntityTypes
{
    public const string Sesion = "sesion";
    public const string Asistencia = "asistencia";
    public const string Participacion = "participacion";
}

/// <summary>Una operación encolada en la tabla SyncQueue del dispositivo.</summary>
public record SyncOperationDto(
    [property: Required] Guid OperationId,          // UUID único de la operación en la cola
    [property: Required] string EntityType,         // sesion | asistencia | participacion
    [property: Required] string Action,             // upsert
    DateTime ClientTimestamp,                       // cuándo ocurrió en el dispositivo (UTC)
    [property: Required] JsonElement Payload);

public record SyncRequest(
    [property: Required] Guid InstructorId,
    [property: Required] string DeviceId,
    [property: Required, MinLength(1)] List<SyncOperationDto> Operations);

public record SyncRejectedDto(Guid OperationId, string Reason);

public record SyncResponse(
    IReadOnlyList<Guid> Processed,                  // aplicadas en SQL Server
    IReadOnlyList<Guid> Duplicates,                 // ya se habían recibido antes (reintento) -> ignoradas
    IReadOnlyList<Guid> Skipped,                    // el servidor tenía un dato más reciente
    IReadOnlyList<SyncRejectedDto> Rejected,        // inválidas (no se deben reintentar)
    DateTime ServerTimeUtc);
