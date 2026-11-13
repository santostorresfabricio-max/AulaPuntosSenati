import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../local/database_helper.dart';
import '../remote/api_client.dart';

/// Resultado de un ciclo de sincronización (para mostrar Snackbars en la UI).
class SyncResult {
  final int sent;
  final int confirmed; // processed + duplicates + skipped -> eliminadas de la cola
  final int rejected;
  final int retryLater;
  final String? error;

  const SyncResult({
    this.sent = 0,
    this.confirmed = 0,
    this.rejected = 0,
    this.retryLater = 0,
    this.error,
  });

  bool get ok => error == null;
}

/// Servicio de sincronización offline -> servidor.
///
/// 1. Escucha los cambios de conectividad (connectivity_plus).
/// 2. Al recuperar la conexión lee los registros pendientes de `sync_queue`.
/// 3. Los envía en lotes a POST /api/sync.
/// 4. Si el servidor responde HTTP 200, elimina de la cola las operaciones confirmadas.
class SyncService {
  SyncService({
    required this.instructorId,
    required this.deviceId,
    DatabaseHelper? db,
    ApiClient? api,
    Connectivity? connectivity,
  })  : _db = db ?? DatabaseHelper.instance,
        _api = api ?? ApiClient(),
        _connectivity = connectivity ?? Connectivity();

  final String instructorId;
  final String deviceId;
  final DatabaseHelper _db;
  final ApiClient _api;
  final Connectivity _connectivity;

  static const int _batchSize = 100;
  static const Duration _periodicInterval = Duration(minutes: 2);

  /// Estado observable desde la UI (punto verde / rojo y contador de pendientes).
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  final StreamController<SyncResult> _results = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get results => _results.stream;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _periodic;
  Timer? _debounce;
  Future<SyncResult>? _inFlight;

  // ------------------------------------------------------------------ Ciclo de vida
  Future<void> start() async {
    _updateOnline(await _connectivity.checkConnectivity());
    await refreshPendingCount();

    _connSub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = isOnline.value;
      _updateOnline(results);

      // Transición offline -> online: sincroniza (con un pequeño debounce porque
      // las redes móviles suelen "parpadear" al reconectar).
      if (!wasOnline && isOnline.value) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 2), syncNow);
      }
    });

    // Respaldo: reintento periódico por si el evento de conectividad no llega.
    _periodic = Timer.periodic(_periodicInterval, (_) {
      if (isOnline.value && pendingCount.value > 0) syncNow();
    });

    if (isOnline.value) unawaited(syncNow());
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
    _periodic?.cancel();
    _debounce?.cancel();
    await _results.close();
    isOnline.dispose();
    pendingCount.dispose();
    isSyncing.dispose();
  }

  void _updateOnline(List<ConnectivityResult> results) {
    isOnline.value = results.any((r) => r != ConnectivityResult.none);
  }

  Future<void> refreshPendingCount() async {
    pendingCount.value = await _db.countPending();
  }

  // ------------------------------------------------------------------ Sincronización
  /// Ejecuta la sincronización. Si ya hay una en curso, devuelve la misma (evita envíos duplicados).
  Future<SyncResult> syncNow() {
    return _inFlight ??= _runSync().whenComplete(() => _inFlight = null);
  }

  Future<SyncResult> _runSync() async {
    if (!isOnline.value) {
      return const SyncResult(error: 'Sin conexión');
    }

    isSyncing.value = true;
    var sent = 0, confirmed = 0, rejected = 0, retry = 0;

    try {
      while (true) {
        final pending = await _db.getPendingOperations(limit: _batchSize);
        if (pending.isEmpty) break;

        final batchIds = pending.map((e) => e.operationId).toList();
        final body = {
          'instructorId': instructorId,
          'deviceId': deviceId,
          'operations': pending
              .map((op) => {
                    'operationId': op.operationId,
                    'entityType': op.entityType,
                    'action': op.action,
                    'clientTimestamp': op.clientTimestamp.toUtc().toIso8601String(),
                    'payload': jsonDecode(op.payload),
                  })
              .toList(),
        };

        final res = await _api.postRaw('/api/sync', body);
        sent += pending.length;

        if (res.statusCode != 200) {
          // Error del servidor (4xx/5xx): la cola NO se toca, se reintentará luego.
          await _db.incrementAttempts(batchIds, 'HTTP ${res.statusCode}: ${res.body}');
          retry += pending.length;
          final result = SyncResult(
              sent: sent, confirmed: confirmed, rejected: rejected, retryLater: retry,
              error: 'El servidor respondió HTTP ${res.statusCode}');
          _results.add(result);
          return result;
        }

        // ---------------- HTTP 200 ----------------
        final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        List<String> ids(String key) =>
            ((json[key] as List?) ?? const []).map((e) => e.toString()).toList();

        // processed / duplicates / skipped: el servidor ya tiene el dato (o uno más reciente)
        // -> se eliminan de la cola local para no volver a enviarlos ni sobrescribir nada.
        final toDelete = [...ids('processed'), ...ids('duplicates'), ...ids('skipped')];
        await _db.deleteOperations(toDelete);
        confirmed += toDelete.length;

        // rejected: inválidas según reglas de negocio -> se marcan como 'failed' para revisión.
        final rejectedMap = <String, String>{
          for (final r in ((json['rejected'] as List?) ?? const []).cast<Map<String, dynamic>>())
            r['operationId'].toString(): r['reason']?.toString() ?? 'Rechazado',
        };
        await _db.markFailed(rejectedMap);
        rejected += rejectedMap.length;

        // Las que no vinieron en ninguna lista (conflicto transitorio) se reintentan después.
        final answered = {...toDelete, ...rejectedMap.keys}.map((e) => e.toLowerCase()).toSet();
        final notAnswered =
            batchIds.where((id) => !answered.contains(id.toLowerCase())).toList();
        if (notAnswered.isNotEmpty) {
          await _db.incrementAttempts(notAnswered, 'Conflicto transitorio en servidor');
          retry += notAnswered.length;
          break; // evita bucle infinito con las mismas operaciones
        }
      }

      // Tras subir los cambios, refresca el catálogo (números oficiales de sesión, nuevos alumnos...).
      await pullCatalog();

      final result = SyncResult(
          sent: sent, confirmed: confirmed, rejected: rejected, retryLater: retry);
      _results.add(result);
      return result;
    } on Exception catch (e) {
      // Timeout / sin internet real / certificado: la cola permanece intacta.
      final result = SyncResult(
          sent: sent, confirmed: confirmed, rejected: rejected, retryLater: retry,
          error: e.toString());
      _results.add(result);
      return result;
    } finally {
      await refreshPendingCount();
      isSyncing.value = false;
    }
  }

  /// Descarga grupos, estudiantes, sesiones y actividades para trabajar offline.
  Future<void> pullCatalog() async {
    final grupos = (await _api.get('/api/instructores/$instructorId/grupos') as List)
        .cast<Map<String, dynamic>>();
    final actividades = (await _api.get('/api/actividades') as List).cast<Map<String, dynamic>>();
    await _db.replaceCatalog(grupos: grupos, actividades: actividades);
  }
}
