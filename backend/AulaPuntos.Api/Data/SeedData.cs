using AulaPuntos.Api.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace AulaPuntos.Api.Data;

/// <summary>
/// Datos iniciales con GUIDs fijos (necesario para HasData) para pruebas de la app.
/// </summary>
public static class SeedData
{
    public static readonly Guid InstructorDemoId = Guid.Parse("8a1f5c2e-0001-4c1a-9a00-000000000001");
    public static readonly Guid GrupoMovilesId = Guid.Parse("8a1f5c2e-0002-4c1a-9a00-000000000001");
    public static readonly Guid GrupoApiId = Guid.Parse("8a1f5c2e-0002-4c1a-9a00-000000000002");
    public static readonly Guid ActividadParticipacionId = Guid.Parse("8a1f5c2e-0004-4c1a-9a00-000000000001");

    public static void Apply(ModelBuilder mb)
    {
        mb.Entity<Instructor>().HasData(new Instructor
        {
            InstructorId = InstructorDemoId,
            Nombres = "Carlos Alberto",
            Apellidos = "Mendoza",
            Correo = "cmendoza@senati.pe",
            Estado = EstadoRegistro.Activo
        });

        mb.Entity<Grupo>().HasData(
            new Grupo { GrupoId = GrupoMovilesId, Codigo = "NRC-48210", Nombre = "Desarrollo de Aplicaciones Móviles Multiplataforma", Periodo = "2026-II", InstructorId = InstructorDemoId },
            new Grupo { GrupoId = GrupoApiId, Codigo = "NRC-48215", Nombre = "Arquitectura de Servicios Web con ASP.NET Core", Periodo = "2026-II", InstructorId = InstructorDemoId });

        var estudiantes = new[]
        {
            ("001458921", "Alejandro Gabriel", "Quispe Mamani", GrupoMovilesId),
            ("001458934", "Valeria Fernanda", "Rojas Huamán", GrupoMovilesId),
            ("001459012", "Diego Sebastián", "Mendoza Chávez", GrupoMovilesId),
            ("001459105", "Camila Lucía", "Flores Paredes", GrupoMovilesId),
            ("001460110", "Rodrigo Alonso", "Sánchez Medina", GrupoApiId),
            ("001460245", "Ariana Belén", "Cruzado Villanueva", GrupoApiId),
        };

        var fechaMatricula = new DateTime(2026, 8, 1, 0, 0, 0, DateTimeKind.Utc);
        for (var i = 0; i < estudiantes.Length; i++)
        {
            var (codigo, nombres, apellidos, grupoId) = estudiantes[i];
            var id = Guid.Parse($"8a1f5c2e-0003-4c1a-9a00-{(i + 1):D12}");
            mb.Entity<Estudiante>().HasData(new Estudiante
            {
                EstudianteId = id, CodigoInstitucional = codigo, Nombres = nombres, Apellidos = apellidos
            });
            mb.Entity<Matricula>().HasData(new Matricula
            {
                GrupoId = grupoId, EstudianteId = id, FechaMatricula = fechaMatricula
            });
        }

        mb.Entity<Actividad>().HasData(
            new Actividad { ActividadId = ActividadParticipacionId, Nombre = "Participación en clase" },
            new Actividad { ActividadId = Guid.Parse("8a1f5c2e-0004-4c1a-9a00-000000000002"), Nombre = "Resolución de reto en laboratorio" },
            new Actividad { ActividadId = Guid.Parse("8a1f5c2e-0004-4c1a-9a00-000000000003"), Nombre = "Apoyo colaborativo a compañeros" });
    }
}
