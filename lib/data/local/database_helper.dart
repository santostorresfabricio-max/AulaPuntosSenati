import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Estados de un registro en la cola de sincronización.
class SyncQueueStatus {
  static const pending = 'pending'; // pendiente de enviar / reintentar
  static const failed = 'failed'; // rechazado por reglas de negocio (no se reintenta)
}

/// Tipos de entidad que viajan al endpoint POST /api/sync.
class SyncEntityType {
  static const sesion = 'sesion';
  static const asistencia = 'asistencia';
  static const participacion = 'participacion';
}

/// Fila de la tabla `sync_queue`.
class SyncQueueItem {
  final int id;
  final String operationId;
  final String entityType;
  final String action;
  final String payload; // JSON
  final DateTime clientTimestamp;
  final int attempts;
  final String status;
  final String? lastError;

  const SyncQueueItem({
    required this.id,
    required this.operationId,
    required this.entityType,
    required this.action,
    required this.payload,
    required this.clientTimestamp,
    required this.attempts,
    required this.status,
    this.lastError,
  });

  factory SyncQueueItem.fromMap(Map<String, Object?> m) => SyncQueueItem(
        id: m['id'] as int,
        operationId: m['operation_id'] as String,
        entityType: m['entity_type'] as String,
        action: m['action'] as String,
        payload: m['payload'] as String,
        clientTimestamp: DateTime.parse(m['client_timestamp'] as String),
        attempts: m['attempts'] as int,
        status: m['status'] as String,
        lastError: m['last_error'] as String?,
      );
}

/// Base de datos local SQLite (offline-first).
///
/// - Tablas de catálogo en modo lectura: grupos, estudiantes, grupo_estudiantes, sesiones, actividades.
/// - Tablas de trabajo local: asistencias, participaciones (para mostrar el estado sin internet).
/// - `sync_queue`: operaciones pendientes de enviar a POST /api/sync.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'aula_puntos_senati.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite (sqflite) no está disponible en Flutter Web.');
    }
    // En escritorio (Windows/Linux) sqflite funciona mediante FFI.
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // ---------------- Catálogos (lectura offline) ----------------
    batch.execute('''
      CREATE TABLE grupos (
        grupo_id       TEXT PRIMARY KEY,
        codigo         TEXT NOT NULL,
        nombre         TEXT NOT NULL,
        periodo        TEXT NOT NULL,
        instructor_id  TEXT NOT NULL,
        actualizado_en TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE estudiantes (
        estudiante_id        TEXT PRIMARY KEY,
        codigo_institucional TEXT NOT NULL UNIQUE,
        nombres              TEXT NOT NULL,
        apellidos            TEXT NOT NULL,
        estado               TEXT NOT NULL DEFAULT 'Activo'
      )''');

    batch.execute('''
      CREATE TABLE grupo_estudiantes (
        grupo_id      TEXT NOT NULL REFERENCES grupos(grupo_id) ON DELETE CASCADE,
        estudiante_id TEXT NOT NULL REFERENCES estudiantes(estudiante_id) ON DELETE CASCADE,
        PRIMARY KEY (grupo_id, estudiante_id)
      )''');

    // sync_status: 'synced' (viene del servidor) | 'pending' (creada offline, aún sin confirmar)
    // numero: NULL mientras la sesión no se sincroniza (lo asigna el servidor).
    batch.execute('''
      CREATE TABLE sesiones (
        sesion_id   TEXT PRIMARY KEY,
        grupo_id    TEXT NOT NULL REFERENCES grupos(grupo_id) ON DELETE CASCADE,
        numero      INTEGER,
        fecha       TEXT NOT NULL,
        tema        TEXT NOT NULL,
        tipo        TEXT NOT NULL,
        estado      TEXT NOT NULL DEFAULT 'Programada',
        sync_status TEXT NOT NULL DEFAULT 'synced'
      )''');

    batch.execute('''
      CREATE TABLE actividades (
        actividad_id TEXT PRIMARY KEY,
        nombre       TEXT NOT NULL
      )''');

    // ---------------- Trabajo local ----------------
    batch.execute('''
      CREATE TABLE asistencias (
        asistencia_id  TEXT PRIMARY KEY,
        sesion_id      TEXT NOT NULL,
        estudiante_id  TEXT NOT NULL,
        estado         TEXT NOT NULL CHECK (estado IN ('presente','tardanza','falta','justificado')),
        fecha_registro TEXT NOT NULL,
        UNIQUE (sesion_id, estudiante_id)
      )''');

    batch.execute('''
      CREATE TABLE participaciones (
        participacion_id TEXT PRIMARY KEY,
        sesion_id        TEXT NOT NULL,
        estudiante_id    TEXT NOT NULL,
        actividad_id     TEXT NOT NULL,
        puntos           INTEGER NOT NULL,
        fecha            TEXT NOT NULL
      )''');
    batch.execute(
        'CREATE INDEX ix_participaciones_sesion ON participaciones(sesion_id, estudiante_id)');

    // ---------------- Cola de sincronización ----------------
    // dedupe_key: permite "compactar" operaciones (ej. si el instructor cambia 3 veces la asistencia
    // de un alumno estando offline, sólo se envía la última).
    batch.execute('''
      CREATE TABLE sync_queue (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_id     TEXT NOT NULL UNIQUE,
        entity_type      TEXT NOT NULL,
        action           TEXT NOT NULL DEFAULT 'upsert',
        payload          TEXT NOT NULL,
        dedupe_key       TEXT,
        client_timestamp TEXT NOT NULL,
        attempts         INTEGER NOT NULL DEFAULT 0,
        status           TEXT NOT NULL DEFAULT 'pending',
        last_error       TEXT,
        created_at       TEXT NOT NULL
      )''');
    batch.execute('CREATE INDEX ix_sync_queue_status ON sync_queue(status, id)');

    await batch.commit(noResult: true);
  }

  // =====================================================================
  // Catálogo (descargado desde GET /api/instructores/{id}/grupos)
  // =====================================================================

  /// Reemplaza el catálogo local con lo que devuelve el servidor, preservando
  /// las sesiones creadas offline que aún no se han sincronizado.
  Future<void> replaceCatalog({
    required List<Map<String, dynamic>> grupos,
    required List<Map<String, dynamic>> actividades,
  }) async {
    final db = await database;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete('grupo_estudiantes');
      await txn.delete('sesiones', where: 'sync_status = ?', whereArgs: ['synced']);
      await txn.delete('actividades');

      for (final g in grupos) {
        await txn.insert(
          'grupos',
          {
            'grupo_id': g['grupoId'],
            'codigo': g['codigo'],
            'nombre': g['nombre'],
            'periodo': g['periodo'],
            'instructor_id': g['instructorId'],
            'actualizado_en': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final e in (g['estudiantes'] as List).cast<Map<String, dynamic>>()) {
          await txn.insert(
            'estudiantes',
            {
              'estudiante_id': e['estudianteId'],
              'codigo_institucional': e['codigoInstitucional'],
              'nombres': e['nombres'],
              'apellidos': e['apellidos'],
              'estado': e['estado'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await txn.insert(
            'grupo_estudiantes',
            {'grupo_id': g['grupoId'], 'estudiante_id': e['estudianteId']},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        for (final s in (g['sesiones'] as List).cast<Map<String, dynamic>>()) {
          // Si la sesión ya fue confirmada por el servidor, pasa a 'synced' con su número oficial.
          await txn.insert(
            'sesiones',
            {
              'sesion_id': s['sesionId'],
              'grupo_id': s['grupoId'],
              'numero': s['numero'],
              'fecha': s['fecha'],
              'tema': s['tema'],
              'tipo': s['tipo'],
              'estado': s['estado'],
              'sync_status': 'synced',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      for (final a in actividades) {
        await txn.insert('actividades', {
          'actividad_id': a['actividadId'],
          'nombre': a['nombre'],
        });
      }
    });
  }

  Future<List<Map<String, Object?>>> getGrupos(String instructorId) async {
    final db = await database;
    return db.query('grupos',
        where: 'instructor_id = ?', whereArgs: [instructorId], orderBy: 'codigo');
  }

  Future<List<Map<String, Object?>>> getEstudiantesDeGrupo(String grupoId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT e.* FROM estudiantes e
      INNER JOIN grupo_estudiantes ge ON ge.estudiante_id = e.estudiante_id
      WHERE ge.grupo_id = ? AND e.estado = 'Activo'
      ORDER BY e.apellidos, e.nombres''', [grupoId]);
  }

  Future<List<Map<String, Object?>>> getSesionesDeGrupo(String grupoId) async {
    final db = await database;
    return db.query('sesiones',
        where: 'grupo_id = ?', whereArgs: [grupoId], orderBy: 'fecha, numero');
  }

  Future<List<Map<String, Object?>>> getActividades() async {
    final db = await database;
    return db.query('actividades', orderBy: 'nombre');
  }

  // =====================================================================
  // Escritura local + encolado (en UNA sola transacción)
  // =====================================================================

  /// Inserta/actualiza una fila local y encola la operación de sincronización de forma atómica:
  /// o se guardan ambas cosas o ninguna.
  Future<void> saveLocalAndEnqueue({
    required String table,
    required Map<String, Object?> row,
    required String operationId,
    required String entityType,
    required Map<String, dynamic> payloadJson,
    required DateTime clientTimestamp,
    String? dedupeKey,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);

      if (dedupeKey != null) {
        // Compacta: elimina operaciones pendientes anteriores sobre el mismo registro.
        await txn.delete('sync_queue',
            where: 'dedupe_key = ? AND status = ?',
            whereArgs: [dedupeKey, SyncQueueStatus.pending]);
      }

      await txn.insert('sync_queue', {
        'operation_id': operationId,
        'entity_type': entityType,
        'action': 'upsert',
        'payload': jsonEncode(payloadJson),
        'dedupe_key': dedupeKey,
        'client_timestamp': clientTimestamp.toUtc().toIso8601String(),
        'attempts': 0,
        'status': SyncQueueStatus.pending,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  /// Marca de asistencia local (una fila por alumno y sesión).
  Future<Map<String, Object?>?> findAsistencia(String sesionId, String estudianteId) async {
    final db = await database;
    final rows = await db.query('asistencias',
        where: 'sesion_id = ? AND estudiante_id = ?',
        whereArgs: [sesionId, estudianteId],
        limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> getPuntosSesion(String sesionId, String estudianteId) async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(puntos),0) AS total FROM participaciones WHERE sesion_id = ? AND estudiante_id = ?',
        [sesionId, estudianteId]);
    return (r.first['total'] as int?) ?? 0;
  }

  // =====================================================================
  // Cola de sincronización
  // =====================================================================

  Future<List<SyncQueueItem>> getPendingOperations({int limit = 200}) async {
    final db = await database;
    final rows = await db.query('sync_queue',
        where: 'status = ?',
        whereArgs: [SyncQueueStatus.pending],
        orderBy: 'id ASC',
        limit: limit);
    return rows.map(SyncQueueItem.fromMap).toList();
  }

  Future<int> countPending() async {
    final db = await database;
    final r = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM sync_queue WHERE status = ?', [SyncQueueStatus.pending]);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Elimina de la cola las operaciones confirmadas por el servidor.
  Future<void> deleteOperations(List<String> operationIds) async {
    if (operationIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(operationIds.length, '?').join(',');
    await db.delete('sync_queue',
        where: 'operation_id IN ($placeholders)', whereArgs: operationIds);
  }

  /// Marca operaciones rechazadas por reglas de negocio (no se vuelven a enviar).
  Future<void> markFailed(Map<String, String> reasonsByOperationId) async {
    if (reasonsByOperationId.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    reasonsByOperationId.forEach((opId, reason) {
      batch.update(
        'sync_queue',
        {'status': SyncQueueStatus.failed, 'last_error': reason},
        where: 'operation_id = ?',
        whereArgs: [opId],
      );
    });
    await batch.commit(noResult: true);
  }

  /// Incrementa el contador de intentos (errores de red / conflictos transitorios).
  Future<void> incrementAttempts(List<String> operationIds, String error) async {
    if (operationIds.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(operationIds.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE operation_id IN ($placeholders)',
      [error, ...operationIds],
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
