using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace AulaPuntos.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Actividades",
                columns: table => new
                {
                    ActividadId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Nombre = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Activa = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Actividades", x => x.ActividadId);
                });

            migrationBuilder.CreateTable(
                name: "Estudiantes",
                columns: table => new
                {
                    EstudianteId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CodigoInstitucional = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Nombres = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Apellidos = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Estado = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Estudiantes", x => x.EstudianteId);
                });

            migrationBuilder.CreateTable(
                name: "Instructores",
                columns: table => new
                {
                    InstructorId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Nombres = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Apellidos = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Correo = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    Estado = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Instructores", x => x.InstructorId);
                });

            migrationBuilder.CreateTable(
                name: "OperacionesSincronizadas",
                columns: table => new
                {
                    OperationId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TipoEntidad = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    InstructorId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProcesadoEnUtc = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OperacionesSincronizadas", x => x.OperationId);
                });

            migrationBuilder.CreateTable(
                name: "Grupos",
                columns: table => new
                {
                    GrupoId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Codigo = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    Nombre = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Periodo = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    InstructorId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Grupos", x => x.GrupoId);
                    table.ForeignKey(
                        name: "FK_Grupos_Instructores_InstructorId",
                        column: x => x.InstructorId,
                        principalTable: "Instructores",
                        principalColumn: "InstructorId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Matriculas",
                columns: table => new
                {
                    GrupoId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    EstudianteId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FechaMatricula = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Matriculas", x => new { x.GrupoId, x.EstudianteId });
                    table.ForeignKey(
                        name: "FK_Matriculas_Estudiantes_EstudianteId",
                        column: x => x.EstudianteId,
                        principalTable: "Estudiantes",
                        principalColumn: "EstudianteId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Matriculas_Grupos_GrupoId",
                        column: x => x.GrupoId,
                        principalTable: "Grupos",
                        principalColumn: "GrupoId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Sesiones",
                columns: table => new
                {
                    SesionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    GrupoId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Numero = table.Column<int>(type: "int", nullable: false),
                    Fecha = table.Column<DateTime>(type: "datetime2", nullable: false),
                    Tema = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    Tipo = table.Column<string>(type: "nvarchar(40)", maxLength: 40, nullable: false),
                    Estado = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    ActualizadoEnUtc = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Sesiones", x => x.SesionId);
                    table.ForeignKey(
                        name: "FK_Sesiones_Grupos_GrupoId",
                        column: x => x.GrupoId,
                        principalTable: "Grupos",
                        principalColumn: "GrupoId",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Asistencias",
                columns: table => new
                {
                    AsistenciaId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SesionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    EstudianteId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Estado = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    FechaRegistro = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SincronizadoEnUtc = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Asistencias", x => x.AsistenciaId);
                    table.CheckConstraint("CK_Asistencias_Estado", "[Estado] IN ('Presente','Tardanza','Falta','Justificado')");
                    table.ForeignKey(
                        name: "FK_Asistencias_Estudiantes_EstudianteId",
                        column: x => x.EstudianteId,
                        principalTable: "Estudiantes",
                        principalColumn: "EstudianteId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Asistencias_Sesiones_SesionId",
                        column: x => x.SesionId,
                        principalTable: "Sesiones",
                        principalColumn: "SesionId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Participaciones",
                columns: table => new
                {
                    ParticipacionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SesionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    EstudianteId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ActividadId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Puntos = table.Column<int>(type: "int", nullable: false),
                    Fecha = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SincronizadoEnUtc = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Participaciones", x => x.ParticipacionId);
                    table.CheckConstraint("CK_Participaciones_Puntos", "[Puntos] BETWEEN -5 AND 5");
                    table.ForeignKey(
                        name: "FK_Participaciones_Actividades_ActividadId",
                        column: x => x.ActividadId,
                        principalTable: "Actividades",
                        principalColumn: "ActividadId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Participaciones_Estudiantes_EstudianteId",
                        column: x => x.EstudianteId,
                        principalTable: "Estudiantes",
                        principalColumn: "EstudianteId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Participaciones_Sesiones_SesionId",
                        column: x => x.SesionId,
                        principalTable: "Sesiones",
                        principalColumn: "SesionId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Actividades",
                columns: new[] { "ActividadId", "Activa", "Nombre" },
                values: new object[,]
                {
                    { new Guid("8a1f5c2e-0004-4c1a-9a00-000000000001"), true, "Participación en clase" },
                    { new Guid("8a1f5c2e-0004-4c1a-9a00-000000000002"), true, "Resolución de reto en laboratorio" },
                    { new Guid("8a1f5c2e-0004-4c1a-9a00-000000000003"), true, "Apoyo colaborativo a compañeros" }
                });

            migrationBuilder.InsertData(
                table: "Estudiantes",
                columns: new[] { "EstudianteId", "Apellidos", "CodigoInstitucional", "Estado", "Nombres" },
                values: new object[,]
                {
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000001"), "Quispe Mamani", "001458921", "Activo", "Alejandro Gabriel" },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000002"), "Rojas Huamán", "001458934", "Activo", "Valeria Fernanda" },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000003"), "Mendoza Chávez", "001459012", "Activo", "Diego Sebastián" },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000004"), "Flores Paredes", "001459105", "Activo", "Camila Lucía" },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000005"), "Sánchez Medina", "001460110", "Activo", "Rodrigo Alonso" },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000006"), "Cruzado Villanueva", "001460245", "Activo", "Ariana Belén" }
                });

            migrationBuilder.InsertData(
                table: "Instructores",
                columns: new[] { "InstructorId", "Apellidos", "Correo", "Estado", "Nombres" },
                values: new object[] { new Guid("8a1f5c2e-0001-4c1a-9a00-000000000001"), "Mendoza", "cmendoza@senati.pe", "Activo", "Carlos Alberto" });

            migrationBuilder.InsertData(
                table: "Grupos",
                columns: new[] { "GrupoId", "Codigo", "InstructorId", "Nombre", "Periodo" },
                values: new object[,]
                {
                    { new Guid("8a1f5c2e-0002-4c1a-9a00-000000000001"), "NRC-48210", new Guid("8a1f5c2e-0001-4c1a-9a00-000000000001"), "Desarrollo de Aplicaciones Móviles Multiplataforma", "2026-II" },
                    { new Guid("8a1f5c2e-0002-4c1a-9a00-000000000002"), "NRC-48215", new Guid("8a1f5c2e-0001-4c1a-9a00-000000000001"), "Arquitectura de Servicios Web con ASP.NET Core", "2026-II" }
                });

            migrationBuilder.InsertData(
                table: "Matriculas",
                columns: new[] { "EstudianteId", "GrupoId", "FechaMatricula" },
                values: new object[,]
                {
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000001"), new Guid("8a1f5c2e-0002-4c1a-9a00-000000000001"), new DateTime(2026, 8, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000002"), new Guid("8a1f5c2e-0002-4c1a-9a00-000000000001"), new DateTime(2026, 8, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000003"), new Guid("8a1f5c2e-0002-4c1a-9a00-000000000001"), new DateTime(2026, 8, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000004"), new Guid("8a1f5c2e-0002-4c1a-9a00-000000000001"), new DateTime(2026, 8, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000005"), new Guid("8a1f5c2e-0002-4c1a-9a00-000000000002"), new DateTime(2026, 8, 1, 0, 0, 0, 0, DateTimeKind.Utc) },
                    { new Guid("8a1f5c2e-0003-4c1a-9a00-000000000006"), new Guid("8a1f5c2e-0002-4c1a-9a00-000000000002"), new DateTime(2026, 8, 1, 0, 0, 0, 0, DateTimeKind.Utc) }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Actividades_Nombre",
                table: "Actividades",
                column: "Nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Asistencias_EstudianteId",
                table: "Asistencias",
                column: "EstudianteId");

            migrationBuilder.CreateIndex(
                name: "IX_Asistencias_SesionId_EstudianteId",
                table: "Asistencias",
                columns: new[] { "SesionId", "EstudianteId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Estudiantes_CodigoInstitucional",
                table: "Estudiantes",
                column: "CodigoInstitucional",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Grupos_Codigo_Periodo",
                table: "Grupos",
                columns: new[] { "Codigo", "Periodo" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Grupos_InstructorId",
                table: "Grupos",
                column: "InstructorId");

            migrationBuilder.CreateIndex(
                name: "IX_Instructores_Correo",
                table: "Instructores",
                column: "Correo",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Matriculas_EstudianteId",
                table: "Matriculas",
                column: "EstudianteId");

            migrationBuilder.CreateIndex(
                name: "IX_Participaciones_ActividadId",
                table: "Participaciones",
                column: "ActividadId");

            migrationBuilder.CreateIndex(
                name: "IX_Participaciones_EstudianteId",
                table: "Participaciones",
                column: "EstudianteId");

            migrationBuilder.CreateIndex(
                name: "IX_Participaciones_SesionId_EstudianteId",
                table: "Participaciones",
                columns: new[] { "SesionId", "EstudianteId" });

            migrationBuilder.CreateIndex(
                name: "IX_Sesiones_GrupoId",
                table: "Sesiones",
                column: "GrupoId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Asistencias");

            migrationBuilder.DropTable(
                name: "Matriculas");

            migrationBuilder.DropTable(
                name: "OperacionesSincronizadas");

            migrationBuilder.DropTable(
                name: "Participaciones");

            migrationBuilder.DropTable(
                name: "Actividades");

            migrationBuilder.DropTable(
                name: "Estudiantes");

            migrationBuilder.DropTable(
                name: "Sesiones");

            migrationBuilder.DropTable(
                name: "Grupos");

            migrationBuilder.DropTable(
                name: "Instructores");
        }
    }
}
