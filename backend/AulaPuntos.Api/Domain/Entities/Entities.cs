namespace AulaPuntos.Api.Domain.Entities;

/// <summary>
/// Estados permitidos para la asistencia. Se persisten como texto en SQL Server
/// y se restringen además con un CHECK constraint (ver AulaPuntosDbContext).
/// </summary>
public enum EstadoAsistencia
{
    Presente,
    Tardanza,
    Falta,
    Justificado
}

public enum EstadoRegistro
{
    Activo,
    Inactivo
}

public enum EstadoSesion
{
    Programada,
    EnCurso,
    Cerrada,
    Anulada
}

/// <summary>
/// Clave primaria: Guid (UUID). Todas las entidades usan UUID para que la app móvil
/// pueda generar identificadores offline sin colisionar con el servidor.
/// </summary>
public class Instructor
{
    public Guid InstructorId { get; set; }
    public string Nombres { get; set; } = string.Empty;
    public string Apellidos { get; set; } = string.Empty;
    public string Correo { get; set; } = string.Empty;
    public EstadoRegistro Estado { get; set; } = EstadoRegistro.Activo;

    public ICollection<Grupo> Grupos { get; set; } = new List<Grupo>();
}

public class Grupo
{
    public Guid GrupoId { get; set; }
    public string Codigo { get; set; } = string.Empty;      // Ej. NRC-48210
    public string Nombre { get; set; } = string.Empty;      // Nombre del curso
    public string Periodo { get; set; } = string.Empty;     // Ej. 2026-II

    public Guid InstructorId { get; set; }
    public Instructor? Instructor { get; set; }

    public ICollection<Matricula> Matriculas { get; set; } = new List<Matricula>();
    public ICollection<Sesion> Sesiones { get; set; } = new List<Sesion>();
}

public class Estudiante
{
    public Guid EstudianteId { get; set; }
    public string CodigoInstitucional { get; set; } = string.Empty; // ID SENATI
    public string Nombres { get; set; } = string.Empty;
    public string Apellidos { get; set; } = string.Empty;
    public EstadoRegistro Estado { get; set; } = EstadoRegistro.Activo;

    public ICollection<Matricula> Matriculas { get; set; } = new List<Matricula>();
}

/// <summary>
/// Tabla puente Grupo &lt;-&gt; Estudiante (relación muchos a muchos).
/// </summary>
public class Matricula
{
    public Guid GrupoId { get; set; }
    public Grupo? Grupo { get; set; }

    public Guid EstudianteId { get; set; }
    public Estudiante? Estudiante { get; set; }

    public DateTime FechaMatricula { get; set; } = DateTime.UtcNow;
}

public class Sesion
{
    public Guid SesionId { get; set; }                     // Puede ser generado en el dispositivo (offline)
    public Guid GrupoId { get; set; }
    public Grupo? Grupo { get; set; }

    public int Numero { get; set; }
    public DateTime Fecha { get; set; }
    public string Tema { get; set; } = string.Empty;
    public string Tipo { get; set; } = "Teoria";
    public EstadoSesion Estado { get; set; } = EstadoSesion.Programada;

    public DateTime ActualizadoEnUtc { get; set; } = DateTime.UtcNow;

    public ICollection<Asistencia> Asistencias { get; set; } = new List<Asistencia>();
    public ICollection<Participacion> Participaciones { get; set; } = new List<Participacion>();
}

public class Asistencia
{
    public Guid AsistenciaId { get; set; }
    public Guid SesionId { get; set; }
    public Sesion? Sesion { get; set; }

    public Guid EstudianteId { get; set; }
    public Estudiante? Estudiante { get; set; }

    public EstadoAsistencia Estado { get; set; }

    /// <summary>Momento en que el instructor marcó la asistencia en el dispositivo (UTC).</summary>
    public DateTime FechaRegistro { get; set; }

    /// <summary>Momento en que el servidor guardó el registro (UTC).</summary>
    public DateTime SincronizadoEnUtc { get; set; } = DateTime.UtcNow;
}

public class Actividad
{
    public Guid ActividadId { get; set; }
    public string Nombre { get; set; } = string.Empty;     // Ej. "Participación en clase"
    public bool Activa { get; set; } = true;

    public ICollection<Participacion> Participaciones { get; set; } = new List<Participacion>();
}

public class Participacion
{
    /// <summary>
    /// Generado por el cliente (UUID v4). Actúa como clave de idempotencia:
    /// reintentar el mismo envío nunca duplica los puntos.
    /// </summary>
    public Guid ParticipacionId { get; set; }

    public Guid SesionId { get; set; }
    public Sesion? Sesion { get; set; }

    public Guid EstudianteId { get; set; }
    public Estudiante? Estudiante { get; set; }

    public Guid ActividadId { get; set; }
    public Actividad? Actividad { get; set; }

    public int Puntos { get; set; }                         // +1, +2, -1
    public DateTime Fecha { get; set; }
    public DateTime SincronizadoEnUtc { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// Registro de operaciones de sincronización ya procesadas (idempotencia del endpoint /api/sync).
/// </summary>
public class OperacionSincronizada
{
    public Guid OperationId { get; set; }
    public string TipoEntidad { get; set; } = string.Empty;
    public string DeviceId { get; set; } = string.Empty;
    public Guid InstructorId { get; set; }
    public DateTime ProcesadoEnUtc { get; set; } = DateTime.UtcNow;
}
