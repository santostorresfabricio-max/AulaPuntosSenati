using AulaPuntos.Api.Contracts;
using AulaPuntos.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace AulaPuntos.Api.Controllers;

/// <summary>
/// Endpoint de sincronización offline -> servidor.
/// POST /api/sync recibe las operaciones encoladas en la tabla SyncQueue (SQLite) del dispositivo.
/// </summary>
[ApiController]
[Route("api/sync")]
[Produces("application/json")]
public class SyncController(SyncService syncService) : ControllerBase
{
    private const int MaxOperacionesPorLote = 500;

    /// <summary>
    /// Procesa un lote de operaciones. Responde HTTP 200 con el resultado de cada operación:
    /// <list type="bullet">
    /// <item><c>processed</c>: aplicadas en SQL Server.</item>
    /// <item><c>duplicates</c>: ya recibidas antes (reintento) – no se vuelven a aplicar.</item>
    /// <item><c>skipped</c>: el servidor tenía un dato más reciente (last-write-wins).</item>
    /// <item><c>rejected</c>: inválidas según reglas de negocio – no deben reintentarse.</item>
    /// </list>
    /// Las operaciones que no aparecen en ninguna lista (conflicto transitorio) deben reintentarse.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(SyncResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status422UnprocessableEntity)]
    public async Task<ActionResult<SyncResponse>> Sync([FromBody] SyncRequest request, CancellationToken ct)
    {
        if (request.Operations.Count > MaxOperacionesPorLote)
            return BadRequest(new { error = $"Máximo {MaxOperacionesPorLote} operaciones por lote." });

        if (request.Operations.Select(o => o.OperationId).Distinct().Count() != request.Operations.Count)
            return BadRequest(new { error = "El lote contiene OperationId repetidos." });

        try
        {
            var result = await syncService.ProcessAsync(request, ct);
            return Ok(result);
        }
        catch (BusinessRuleException ex)
        {
            return UnprocessableEntity(new { error = ex.Message });
        }
    }
}
