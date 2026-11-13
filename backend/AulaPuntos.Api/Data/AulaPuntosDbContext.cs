using AulaPuntos.Api.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AulaPuntos.Api.Data;

public class AulaPuntosDbContext(DbContextOptions<AulaPuntosDbContext> options) : DbContext(options)
{
    public DbSet<Instructor> Instructores => Set<Instructor>();
    public DbSet<Grupo> Grupos => Set<Grupo>();
    public DbSet<Estudiante> Estudiantes => Set<Estudiante>();
    public DbSet<Matricula> Matriculas => Set<Matricula>();
    public DbSet<Sesion> Sesiones => Set<Sesion>();
    public DbSet<Asistencia> Asistencias => Set<Asistencia>();
    public DbSet<Actividad> Actividades => Set<Actividad>();
    public DbSet<Participacion> Participaciones => Set<Participacion>();
    public DbSet<OperacionSincronizada> OperacionesSincronizadas => Set<OperacionSincronizada>();

    protected override void OnModelCreating(ModelBuilder mb)
    {
        // ---------- Instructor ----------
        mb.Entity<Instructor>(e =>
        {
            e.ToTable("Instructores");
            e.HasKey(x => x.InstructorId);
            e.Property(x => x.Nombres).HasMaxLength(100).IsRequired();
            e.Property(x => x.Apellidos).HasMaxLength(100).IsRequired();
            e.Property(x => x.Correo).HasMaxLength(150).IsRequired();
            e.HasIndex(x => x.Correo).IsUnique();
            e.Property(x => x.Estado).HasConversion<string>().HasMaxLength(20);
        });

        // ---------- Grupo ----------
        mb.Entity<Grupo>(e =>
        {
            e.ToTable("Grupos");
            e.HasKey(x => x.GrupoId);
            e.Property(x => x.Codigo).HasMaxLength(30).IsRequired();
            e.Property(x => x.Nombre).HasMaxLength(200).IsRequired();
            e.Property(x => x.Periodo).HasMaxLength(20).IsRequired();
            e.HasIndex(x => new { x.Codigo, x.Periodo }).IsUnique();

            e.HasOne(x => x.Instructor)
             .WithMany(i => i.Grupos)
             .HasForeignKey(x => x.InstructorId)
             .OnDelete(DeleteBehavior.Restrict);
        });

        // ---------- Estudiante ----------
        mb.Entity<Estudiante>(e =>
        {
            e.ToTable("Estudiantes");
            e.HasKey(x => x.EstudianteId);
            e.Property(x => x.CodigoInstitucional).HasMaxLength(20).IsRequired();
            e.HasIndex(x => x.CodigoInstitucional).IsUnique();
            e.Property(x => x.Nombres).HasMaxLength(100).IsRequired();
            e.Property(x => x.Apellidos).HasMaxLength(100).IsRequired();
            e.Property(x => x.Estado).HasConversion<string>().HasMaxLength(20);
        });

        // ---------- Matricula (Grupo <-> Estudiante) ----------
        mb.Entity<Matricula>(e =>
        {
            e.ToTable("Matriculas");
            e.HasKey(x => new { x.GrupoId, x.EstudianteId });
            e.HasOne(x => x.Grupo).WithMany(g => g.Matriculas)
             .HasForeignKey(x => x.GrupoId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Estudiante).WithMany(s => s.Matriculas)
             .HasForeignKey(x => x.EstudianteId).OnDelete(DeleteBehavior.Cascade);
        });

        // ---------- Sesion ----------
        mb.Entity<Sesion>(e =>
        {
            e.ToTable("Sesiones");
            e.HasKey(x => x.SesionId);
            e.Property(x => x.SesionId).ValueGeneratedNever(); // lo genera el cliente
            e.Property(x => x.Tema).HasMaxLength(300).IsRequired();
            e.Property(x => x.Tipo).HasMaxLength(40).IsRequired();
            e.Property(x => x.Estado).HasConversion<string>().HasMaxLength(20);

            e.HasOne(x => x.Grupo).WithMany(g => g.Sesiones)
             .HasForeignKey(x => x.GrupoId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---------- Asistencia ----------
        mb.Entity<Asistencia>(e =>
        {
            e.ToTable("Asistencias", t => t.HasCheckConstraint(
                "CK_Asistencias_Estado",
                "[Estado] IN ('Presente','Tardanza','Falta','Justificado')"));
            e.HasKey(x => x.AsistenciaId);
            e.Property(x => x.AsistenciaId).ValueGeneratedNever();
            e.Property(x => x.Estado).HasConversion<string>().HasMaxLength(20).IsRequired();

            // Un estudiante tiene UN solo registro de asistencia por sesión.
            e.HasIndex(x => new { x.SesionId, x.EstudianteId }).IsUnique();

            e.HasOne(x => x.Sesion).WithMany(s => s.Asistencias)
             .HasForeignKey(x => x.SesionId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Estudiante).WithMany()
             .HasForeignKey(x => x.EstudianteId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---------- Actividad ----------
        mb.Entity<Actividad>(e =>
        {
            e.ToTable("Actividades");
            e.HasKey(x => x.ActividadId);
            e.Property(x => x.Nombre).HasMaxLength(150).IsRequired();
            e.HasIndex(x => x.Nombre).IsUnique();
        });

        // ---------- Participacion ----------
        mb.Entity<Participacion>(e =>
        {
            e.ToTable("Participaciones", t => t.HasCheckConstraint(
                "CK_Participaciones_Puntos", "[Puntos] BETWEEN -5 AND 5"));
            e.HasKey(x => x.ParticipacionId);
            e.Property(x => x.ParticipacionId).ValueGeneratedNever(); // clave de idempotencia
            e.HasIndex(x => new { x.SesionId, x.EstudianteId });

            e.HasOne(x => x.Sesion).WithMany(s => s.Participaciones)
             .HasForeignKey(x => x.SesionId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Estudiante).WithMany()
             .HasForeignKey(x => x.EstudianteId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Actividad).WithMany(a => a.Participaciones)
             .HasForeignKey(x => x.ActividadId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---------- Operaciones de sincronización (idempotencia) ----------
        mb.Entity<OperacionSincronizada>(e =>
        {
            e.ToTable("OperacionesSincronizadas");
            e.HasKey(x => x.OperationId);
            e.Property(x => x.OperationId).ValueGeneratedNever();
            e.Property(x => x.TipoEntidad).HasMaxLength(30);
            e.Property(x => x.DeviceId).HasMaxLength(100);
        });

        SeedData.Apply(mb);
    }
}
