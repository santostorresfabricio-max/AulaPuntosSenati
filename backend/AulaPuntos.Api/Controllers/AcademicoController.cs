using AulaPuntos.Api.Contracts;
using AulaPuntos.Api.Data;
using AulaPuntos.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace AulaPuntos.Api.Controllers;

/// <summary>
/// Endpoints de operación en línea. El instructor se identifica temporalmente con la cabecera
/// <c>X-Instructor-Id</c>; en una fase posterior se reemplazará por el claim del token JWT.
/// </summary>
[ApiController]
[Route("api")]
[Produces("application/json")]
public class AcademicoController(AcademicRulesService rules, AulaPuntosDbContext db) : ControllerBase
{
    private const string InstructorHeader = "X-Instructor-Id";

    private bool TryGetInstructorId(out Guid instructorId) =>
        Guid.TryParse(Request.Headers[InstructorHeader].FirstOrDefault(), out instructorId);

    /// <summary>Grupos del instructor con sus estudiantes y sesiones (para cachear en SQLite).</summary>
    [HttpGet("instructores/{instructorId:guid}/grupos")]
    public async Task<ActionResult<IReadOnlyList<GrupoDto>>> GetGrupos(Guid instructorId, CancellationToken ct) =>
        Ok(await rules.GetGruposDeInstructorAsync(instructorId, ct));

    [HttpGet("actividades")]
    public async Task<ActionResult<IReadOnlyList<ActividadDto>>> GetActividades(CancellationToken ct) =>
        Ok(await rules.GetActividadesAsync(ct));

    [HttpPost("sesiones")]
    public Task<IActionResult> CrearSesion([FromBody] CrearSesionRequest req, CancellationToken ct) =>
        Execute(id => rules.UpsertSesionAsync(id, req, DateTime.UtcNow, ct), ct);

    [HttpPost("asistencias")]
    public Task<IActionResult> RegistrarAsistencia([FromBody] RegistrarAsistenciaRequest req, CancellationToken ct) =>
        Execute(id => rules.UpsertAsistenciaAsync(id, req, ct), ct);

    [HttpPost("participaciones")]
    public Task<IActionResult> RegistrarParticipacion([FromBody] RegistrarParticipacionRequest req, CancellationToken ct) =>
        Execute(id => rules.RegistrarParticipacionAsync(id, req, ct), ct);

    private async Task<IActionResult> Execute(Func<Guid, Task<ApplyResult>> action, CancellationToken ct)
    {
        if (!TryGetInstructorId(out var instructorId))
            return Unauthorized(new { error = $"Cabecera {InstructorHeader} requerida." });

        try
        {
            var result = await action(instructorId);
            await db.SaveChangesAsync(ct);
            // Un reintento duplicado responde 200 igual que el original: el cliente no debe tratarlo como error.
            return Ok(new { result = result.ToString() });
        }
        catch (BusinessRuleException ex)
        {
            return UnprocessableEntity(new { error = ex.Message });
        }
    }
}
