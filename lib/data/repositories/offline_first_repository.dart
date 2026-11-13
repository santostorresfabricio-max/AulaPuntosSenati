import 'package:uuid/uuid.dart';

import '../local/database_helper.dart';
import '../sync/sync_service.dart';

/// Repositorio offline-first: TODA escritura se guarda primero en SQLite y se encola en
/// `sync_queue`. Si hay conexiÃ³n se dispara la sincronizaciÃ³n inmediatamente; si no,
/// queda pendiente hasta que SyncService detecte la reconexiÃ³n.
class OfflineFirstRepository {
  OfflineFirstRepository({required this.syncService, DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final SyncService syncService;
  final DatabaseHelper _db;
  static const _uuid = Uuid();

  /// Crea una sesiÃ³n offline. El UUID se genera en el dispositivo y es definitivo:
  /// el servidor lo respeta, asÃ­ las asistencias/puntos que la referencian siguen siendo vÃ¡lidos.
  Future<String> crearSesion({
    required String grupoId,
    required String tema,
    required DateTime fecha,
    required String tipo,
  }) async {
    final sesionId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final payload = {
      'sesionId': sesionId,
      'grupoId': grupoId,
      'fecha': fecha.toUtc().toIso8601String(),
      'tema': tema,
      'tipo': tipo,
    };

    await _db.saveLocalAndEnqueue(
      table: 'sesiones',
      row: {
        'sesion_id': sesionId,
        'grupo_id': grupoId,
        'numero': null, // lo asigna el servidor al sincronizar
        'fecha': payload['fecha'],
        'tema': tema,
        'tipo': tipo,
        'estado': 'Programada',
        'sync_status': 'pending',
      },
      operationId: _uuid.v4(),
      entityType: SyncEntityType.sesion,
      payloadJson: payload,
      clientTimestamp: now,
      dedupeKey: 'sesion:$sesionId',
    );

    await _afterWrite();
    return sesionId;
  }

  /// Marca asistencia (1 toque). estado: presente | tardanza | falta | justificado
  Future<void> marcarAsistencia({
    required String sesionId,
    required String estudianteId,
    required String estado,
  }) async {
    const permitidos = {'presente', 'tardanza', 'falta', 'justificado'};
    final estadoNorm = estado.toLowerCase();
    if (!permitidos.contains(estadoNorm)) {
      throw ArgumentError('Estado de asistencia no permitido: $estado');
    }

    final existente = await _db.findAsistencia(sesionId, estudianteId);
    final asistenciaId = (existente?['asistencia_id'] as String?) ?? _uuid.v4();
    final now = DateTime.now().toUtc();

    final payload = {
      'asistenciaId': asistenciaId,
      'sesionId': sesionId,
      'estudianteId': estudianteId,
      'estado': estadoNorm,
      'fechaRegistro': now.toIso8601String(),
    };

    await _db.saveLocalAndEnqueue(
      table: 'asistencias',
      row: {
        'asistencia_id': asistenciaId,
        'sesion_id': sesionId,
        'estudiante_id': estudianteId,
        'estado': estadoNorm,
        'fecha_registro': now.toIso8601String(),
      },
      operationId: _uuid.v4(),
      entityType: SyncEntityType.asistencia,
      payloadJson: payload,
      clientTimestamp: now,
      // SÃ³lo la Ãºltima marca por alumno/sesiÃ³n viaja al servidor.
      dedupeKey: 'asistencia:$sesionId:$estudianteId',
    );

    await _afterWrite();
  }

  /// Registra puntos (+1, +2, -1). Cada toque genera un ParticipacionId nuevo que el
  /// servidor usa como clave de idempotencia (reintentos = sin duplicados).
  Future<void> registrarPuntos({
    required String sesionId,
    required String estudianteId,
    required String actividadId,
    required int puntos,
  }) async {
    final participacionId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final payload = {
      'participacionId': participacionId,
      'sesionId': sesionId,
      'estudianteId': estudianteId,
      'actividadId': actividadId,
      'puntos': puntos,
      'fecha': now.toIso8601String(),
    };

    await _db.saveLocalAndEnqueue(
      table: 'participaciones',
      row: {
        'participacion_id': participacionId,
        'sesion_id': sesionId,
        'estudiante_id': estudianteId,
        'actividad_id': actividadId,
        'puntos': puntos,
        'fecha': now.toIso8601String(),
      },
      operationId: _uuid.v4(),
      entityType: SyncEntityType.participacion,
      payloadJson: payload,
      clientTimestamp: now,
      // Sin dedupe_key: cada toque es un evento distinto que debe sumarse.
    );

    await _afterWrite();
  }

  Future<void> _afterWrite() async {
    await syncService.refreshPendingCount();
    if (syncService.isOnline.value) {
      // Online: se envÃ­a de inmediato. Si falla, la operaciÃ³n sigue segura en la cola.
      syncService.syncNow();
    }
  }
}
