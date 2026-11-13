using AulaPuntos.Api.Data;
using AulaPuntos.Api.Domain.Entities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AulaPuntos.Api.Controllers;

/// <summary>
/// DTO seguro y minimalista por estudiante (sin correos, teléfonos, ni IDs internos sensibles).
/// Solo expone Código Institucional, Nombres y el Total de Puntos/Asistencias.
/// </summary>
public record ConsolidatedStudentReportDto(
    string CodigoInstitucional,
    string NombresCompletos,
    int Presentes,
    int Tardanzas,
    int Faltas,
    int Justificados,
    int TotalAsistenciasRegistradas,
    int TotalPuntos);

/// <summary>
/// Cabecera y resumen consolidado con verificación de integridad contra registros de origen.
/// </summary>
public record ConsolidatedReportResponse(
    string GrupoCodigo,
    string GrupoNombre,
    string Periodo,
    string SesionOAlcance,
    DateTime FechaGeneracionUtc,
    string CriteriosFiltroAplicados,
    bool IntegridadVerificada,
    int TotalPuntosConsolidado,
    int TotalAsistenciasConsolidado,
    IReadOnlyList<ConsolidatedStudentReportDto> Estudiantes);

[ApiController]
[Route("api/reports")]
[Produces("application/json")]
public class ReportsController(AulaPuntosDbContext db) : ControllerBase
{
    /// <summary>
    /// Devuelve el reporte consolidado de asistencia y puntos aplicando filtros opcionales:
    /// grupoId, sesionId, fechaInicio, fechaFin y busquedaEstudiante (código o nombre).
    /// </summary>
    [HttpGet("consolidated")]
    [ProducesResponseType(typeof(ConsolidatedReportResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ConsolidatedReportResponse>> GetConsolidatedReport(
        [FromQuery] Guid grupoId,
        [FromQuery] Guid? sesionId = null,
        [FromQuery] DateTime? fechaInicio = null,
        [FromQuery] DateTime? fechaFin = null,
        [FromQuery] string? busquedaEstudiante = null,
        CancellationToken ct = default)
    {
        if (grupoId == Guid.Empty)
            return BadRequest(new { error = "El parámetro grupoId es obligatorio." });

        var grupo = await db.Grupos
            .AsNoTracking()
            .FirstOrDefaultAsync(g => g.GrupoId == grupoId, ct);

        if (grupo is null)
            return NotFound(new { error = $"No se encontró el grupo con ID {grupoId}." });

        // 1. Filtrar las sesiones del grupo que entran en el alcance del reporte
        var sesionesQuery = db.Sesiones
            .AsNoTracking()
            .Where(s => s.GrupoId == grupoId && s.Estado != EstadoSesion.Anulada);

        if (sesionId.HasValue && sesionId.Value != Guid.Empty)
            sesionesQuery = sesionesQuery.Where(s => s.SesionId == sesionId.Value);

        if (fechaInicio.HasValue)
            sesionesQuery = sesionesQuery.Where(s => s.Fecha >= fechaInicio.Value.Date);

        if (fechaFin.HasValue)
        {
            var finDia = fechaFin.Value.Date.AddDays(1).AddTicks(-1);
            sesionesQuery = sesionesQuery.Where(s => s.Fecha <= finDia);
        }

        var sesionesFiltradas = await sesionesQuery
            .OrderBy(s => s.Numero)
            .Select(s => new { s.SesionId, s.Numero, s.Tema, s.Fecha })
            .ToListAsync(ct);

        var sesionIds = sesionesFiltradas.Select(s => s.SesionId).ToHashSet();

        // 2. Filtrar los estudiantes matriculados en el grupo (por código o nombres/apellidos)
        var estudiantesQuery = db.Matriculas
            .AsNoTracking()
            .Where(m => m.GrupoId == grupoId && m.Estudiante!.Estado == EstadoRegistro.Activo)
            .Select(m => m.Estudiante!);

        if (!string.IsNullOrWhiteSpace(busquedaEstudiante))
        {
            var term = busquedaEstudiante.Trim().ToLower();
            estudiantesQuery = estudiantesQuery.Where(e =>
                e.CodigoInstitucional.ToLower().Contains(term) ||
                e.Nombres.ToLower().Contains(term) ||
                e.Apellidos.ToLower().Contains(term));
        }

        var estudiantes = await estudiantesQuery
            .OrderBy(e => e.Apellidos)
            .ThenBy(e => e.Nombres)
            .Select(e => new
            {
                e.EstudianteId,
                e.CodigoInstitucional,
                NombresCompletos = $"{e.Apellidos}, {e.Nombres}"
            })
            .ToListAsync(ct);

        var estudianteIds = estudiantes.Select(e => e.EstudianteId).ToHashSet();

        // 3. Obtener registros de origen (Asistencias y Participaciones) dentro del filtro
        var asistenciasOrigen = await db.Asistencias
            .AsNoTracking()
            .Where(a => sesionIds.Contains(a.SesionId) && estudianteIds.Contains(a.EstudianteId))
            .ToListAsync(ct);

        var participacionesOrigen = await db.Participaciones
            .AsNoTracking()
            .Where(p => sesionIds.Contains(p.SesionId) && estudianteIds.Contains(p.EstudianteId))
            .ToListAsync(ct);

        // 4. Agrupación LINQ por estudiante para calcular los totales
        var asistenciasAgrupadas = asistenciasOrigen
            .GroupBy(a => a.EstudianteId)
            .ToDictionary(
                g => g.Key,
                g => new
                {
                    Presentes = g.Count(x => x.Estado == EstadoAsistencia.Presente),
                    Tardanzas = g.Count(x => x.Estado == EstadoAsistencia.Tardanza),
                    Faltas = g.Count(x => x.Estado == EstadoAsistencia.Falta),
                    Justificados = g.Count(x => x.Estado == EstadoAsistencia.Justificado),
                    Total = g.Count()
                });

        var puntosAgrupados = participacionesOrigen
            .GroupBy(p => p.EstudianteId)
            .ToDictionary(
                g => g.Key,
                g => g.Sum(x => x.Puntos));

        var filasConsolidado = estudiantes.Select(est =>
        {
            asistenciasAgrupadas.TryGetValue(est.EstudianteId, out var asist);
            puntosAgrupados.TryGetValue(est.EstudianteId, out var pts);

            return new ConsolidatedStudentReportDto(
                CodigoInstitucional: est.CodigoInstitucional,
                NombresCompletos: est.NombresCompletos,
                Presentes: asist?.Presentes ?? 0,
                Tardanzas: asist?.Tardanzas ?? 0,
                Faltas: asist?.Faltas ?? 0,
                Justificados: asist?.Justificados ?? 0,
                TotalAsistenciasRegistradas: asist?.Total ?? 0,
                TotalPuntos: pts);
        }).ToList();

        // 5. Regla de Negocio: Verificación de integridad (totales calculados == registros de origen)
        var sumaPuntosConsolidada = filasConsolidado.Sum(r => r.TotalPuntos);
        var sumaPuntosOrigen = participacionesOrigen.Sum(p => p.Puntos);

        var sumaAsistenciasConsolidada = filasConsolidado.Sum(r =>
            r.Presentes + r.Tardanzas + r.Faltas + r.Justificados);
        var sumaAsistenciasOrigen = asistenciasOrigen.Count;

        var integridadOk = sumaPuntosConsolidada == sumaPuntosOrigen &&
                           sumaAsistenciasConsolidada == sumaAsistenciasOrigen;

        if (!integridadOk)
        {
            return StatusCode(StatusCodes.Status500InternalServerError, new
            {
                error = "Inconsistencia detectada entre los totales consolidados y los registros de origen."
            });
        }

        // 6. Construir metadatos de cabecera obligatorios
        var alcanceSesion = sesionId.HasValue && sesionesFiltradas.Count == 1
            ? $"Sesión N° {sesionesFiltradas[0].Numero}: {sesionesFiltradas[0].Tema} ({sesionesFiltradas[0].Fecha:dd/MM/yyyy})"
            : $"Periodo {grupo.Periodo} ({sesionesFiltradas.Count} sesiones evaluadas)";

        var criterios = new List<string> { $"Grupo: {grupo.Codigo}" };
        if (sesionId.HasValue) criterios.Add("Sesión específica");
        if (fechaInicio.HasValue) criterios.Add($"Desde: {fechaInicio.Value:dd/MM/yyyy}");
        if (fechaFin.HasValue) criterios.Add($"Hasta: {fechaFin.Value:dd/MM/yyyy}");
        if (!string.IsNullOrWhiteSpace(busquedaEstudiante))
            criterios.Add($"Estudiante: \"{busquedaEstudiante.Trim()}\"");

        return Ok(new ConsolidatedReportResponse(
            GrupoCodigo: grupo.Codigo,
            GrupoNombre: grupo.Nombre,
            Periodo: grupo.Periodo,
            SesionOAlcance: alcanceSesion,
            FechaGeneracionUtc: DateTime.UtcNow,
            CriteriosFiltroAplicados: string.Join(" | ", criterios),
            IntegridadVerificada: true,
            TotalPuntosConsolidado: sumaPuntosConsolidada,
            TotalAsistenciasConsolidado: sumaAsistenciasConsolidada,
            Estudiantes: filasConsolidado));
    }
}
