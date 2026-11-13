import 'package:flutter/material.dart';
import '../../data/mock/mock_senati_repository.dart';
import '../../domain/entities/models.dart';
import '../../domain/entities/report_models.dart';

class AppController extends ChangeNotifier {
  // Estado de Autenticación
  bool _isAuthenticated = false;
  String _instructorName = 'Ing. Carlos Alberto Mendoza';
  final String _instructorCode = 'INST-SENATI-8842';
  final String _zonalCampus = 'CFP Lima - Independencia (Escuela ETI)';

  // Estado de Conectividad (Online / Offline)
  bool _isOnline = true;
  int _pendingSyncCount = 0;

  // Navegación principal (0: Dashboard, 1: Grupos, 2: Asistencia, 3: Puntos, 4: Reportes)
  int _selectedNavIndex = 0;

  // Datos de Dominio
  late List<GroupEntity> _groups;
  late List<SessionEntity> _sessions;
  late List<StudentEntity> _students;
  late List<String> _activities;

  // Selección activa para agilizar el flujo entre módulos
  late String _selectedGroupId;
  late String _selectedSessionId;
  late String _selectedActivity;

  // Registros de Asistencia: Map<sessionId, Map<studentId, AttendanceStatus>>
  final Map<String, Map<String, AttendanceStatus>> _attendanceMap = {};

  // Registros de Puntos Acumulados por Estudiante: Map<studentId, int>
  final Map<String, int> _studentTotalPoints = {};

  // Historial de transacciones de puntos
  final List<PointTransaction> _pointTransactions = [];

  AppController() {
    _initMockData();
  }

  void _initMockData() {
    _groups = List.from(MockSenatiRepository.getInitialGroups());
    _sessions = List.from(MockSenatiRepository.getInitialSessions());
    _students = List.from(MockSenatiRepository.getInitialStudents());
    _activities = List.from(MockSenatiRepository.getPredefinedActivities());

    _selectedGroupId = _groups.first.id;
    _selectedSessionId = _sessions
        .where((s) => s.groupId == _selectedGroupId)
        .last
        .id;
    _selectedActivity = _activities.first;

    // Inicializar datos de ejemplo para que el instructor vea datos reales de inmediato
    for (final student in _students) {
      _studentTotalPoints[student.id] = (student.id.hashCode.abs() % 6) + 2;
    }

    for (final session in _sessions) {
      _attendanceMap[session.id] = {};
      final groupStudents =
          _students.where((s) => s.groupId == session.groupId).toList();
      for (int i = 0; i < groupStudents.length; i++) {
        final st = groupStudents[i];
        if (i % 7 == 5) {
          _attendanceMap[session.id]![st.id] = AttendanceStatus.late;
        } else if (i % 9 == 7) {
          _attendanceMap[session.id]![st.id] = AttendanceStatus.excused;
        } else {
          _attendanceMap[session.id]![st.id] = AttendanceStatus.present;
        }
      }
    }
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String get instructorName => _instructorName;
  String get instructorCode => _instructorCode;
  String get zonalCampus => _zonalCampus;

  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;
  int get selectedNavIndex => _selectedNavIndex;

  List<GroupEntity> get groups => List.unmodifiable(_groups);
  List<String> get activities => List.unmodifiable(_activities);
  List<PointTransaction> get pointTransactions =>
      List.unmodifiable(_pointTransactions);

  GroupEntity get selectedGroup =>
      _groups.firstWhere((g) => g.id == _selectedGroupId, orElse: () => _groups.first);

  List<SessionEntity> getSessionsForGroup(String groupId) {
    final list = _sessions.where((s) => s.groupId == groupId).toList();
    list.sort((a, b) => a.sessionNumber.compareTo(b.sessionNumber));
    return list;
  }

  SessionEntity? get selectedSession {
    final groupSessions = getSessionsForGroup(_selectedGroupId);
    if (groupSessions.isEmpty) return null;
    return groupSessions.firstWhere(
      (s) => s.id == _selectedSessionId,
      orElse: () => groupSessions.last,
    );
  }

  String get selectedActivity => _selectedActivity;

  List<StudentEntity> getStudentsForGroup(String groupId) {
    return _students.where((s) => s.groupId == groupId).toList();
  }

  int get totalStudentsCount => _students.length;
  int get totalSessionsCount => _sessions.length;

  // Acciones de Autenticación
  void login(String username, String password) {
    if (username.trim().isNotEmpty) {
      if (username.contains('@')) {
        final prefix = username.split('@').first.replaceAll('.', ' ');
        _instructorName = 'Ing. ${_capitalizeWords(prefix)}';
      }
    }
    _isAuthenticated = true;
    _selectedNavIndex = 0;
    notifyListeners();
  }

  String _capitalizeWords(String input) {
    return input
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  // Navegación
  void navigateTo(int index, {String? groupId, String? sessionId}) {
    if (groupId != null) {
      _selectedGroupId = groupId;
      final groupSessions = getSessionsForGroup(groupId);
      if (groupSessions.isNotEmpty) {
        _selectedSessionId = sessionId ?? groupSessions.last.id;
      }
    } else if (sessionId != null) {
      _selectedSessionId = sessionId;
    }
    _selectedNavIndex = index;
    notifyListeners();
  }

  // Conectividad Online / Offline
  void toggleConnectivity() {
    _isOnline = !_isOnline;
    if (_isOnline && _pendingSyncCount > 0) {
      _pendingSyncCount = 0;
    }
    notifyListeners();
  }

  void _registerLocalOrRemoteChange() {
    if (!_isOnline) {
      _pendingSyncCount++;
    }
  }

  // Selección de Grupo, Sesión y Actividad
  void selectGroup(String groupId) {
    _selectedGroupId = groupId;
    final groupSessions = getSessionsForGroup(groupId);
    if (groupSessions.isNotEmpty) {
      _selectedSessionId = groupSessions.last.id;
    }
    notifyListeners();
  }

  void selectSession(String sessionId) {
    _selectedSessionId = sessionId;
    notifyListeners();
  }

  void selectActivity(String activity) {
    _selectedActivity = activity;
    notifyListeners();
  }

  void addCustomActivity(String newActivity) {
    final trimmed = newActivity.trim();
    if (trimmed.isEmpty) return;
    if (!_activities.contains(trimmed)) {
      _activities.insert(0, trimmed);
    }
    _selectedActivity = trimmed;
    notifyListeners();
  }

  // Crear Nueva Sesión
  SessionEntity createSession({
    required String groupId,
    required String topic,
    required DateTime date,
    required SessionType type,
  }) {
    final currentSessions = getSessionsForGroup(groupId);
    final nextNumber = currentSessions.isEmpty
        ? 1
        : currentSessions.map((s) => s.sessionNumber).reduce((a, b) => a > b ? a : b) + 1;

    final newSession = SessionEntity(
      id: 'SES-${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      sessionNumber: nextNumber,
      topic: topic.trim(),
      date: date,
      type: type,
    );

    _sessions.add(newSession);
    _selectedGroupId = groupId;
    _selectedSessionId = newSession.id;

    // Inicializar asistencia por defecto como Presente para ahorrar clics al instructor
    _attendanceMap[newSession.id] = {};
    for (final student in getStudentsForGroup(groupId)) {
      _attendanceMap[newSession.id]![student.id] = AttendanceStatus.present;
    }

    _registerLocalOrRemoteChange();
    notifyListeners();
    return newSession;
  }

  // Gestión de Asistencia (1 clic)
  AttendanceStatus getAttendance(String sessionId, String studentId) {
    return _attendanceMap[sessionId]?[studentId] ?? AttendanceStatus.present;
  }

  void setAttendance({
    required String sessionId,
    required String studentId,
    required AttendanceStatus status,
  }) {
    _attendanceMap.putIfAbsent(sessionId, () => {});
    _attendanceMap[sessionId]![studentId] = status;
    _registerLocalOrRemoteChange();
    notifyListeners();
  }

  void markAllAttendance({
    required String sessionId,
    required String groupId,
    required AttendanceStatus status,
  }) {
    _attendanceMap.putIfAbsent(sessionId, () => {});
    for (final student in getStudentsForGroup(groupId)) {
      _attendanceMap[sessionId]![student.id] = status;
    }
    _registerLocalOrRemoteChange();
    notifyListeners();
  }

  Map<AttendanceStatus, int> getAttendanceSummary(String sessionId, String groupId) {
    final counts = {
      AttendanceStatus.present: 0,
      AttendanceStatus.late: 0,
      AttendanceStatus.absent: 0,
      AttendanceStatus.excused: 0,
    };
    final students = getStudentsForGroup(groupId);
    for (final s in students) {
      final st = getAttendance(sessionId, s.id);
      counts[st] = (counts[st] ?? 0) + 1;
    }
    return counts;
  }

  // Gestión de Puntuación Rápida (+1, +2, -1)
  int getStudentPoints(String studentId) {
    return _studentTotalPoints[studentId] ?? 0;
  }

  int getSessionStudentPoints(String sessionId, String studentId) {
    return _pointTransactions
        .where((t) => t.sessionId == sessionId && t.studentId == studentId)
        .fold(0, (sum, item) => sum + item.delta);
  }

  void updateStudentPoints({
    required String studentId,
    required String sessionId,
    required String activityName,
    required int delta,
  }) {
    final current = _studentTotalPoints[studentId] ?? 0;
    final updated = (current + delta) < 0 ? 0 : (current + delta);
    _studentTotalPoints[studentId] = updated;

    _pointTransactions.insert(
      0,
      PointTransaction(
        id: 'PT-${DateTime.now().microsecondsSinceEpoch}',
        studentId: studentId,
        sessionId: sessionId,
        activityName: activityName,
        delta: delta,
        timestamp: DateTime.now(),
        synced: _isOnline,
      ),
    );

    _registerLocalOrRemoteChange();
    notifyListeners();
  }

  /// Construye el reporte consolidado aplicando filtros por grupo, sesión
  /// opcional, rango de fechas y búsqueda por estudiante, verificando que los
  /// totales calculados coincidan con los registros de origen.
  ConsolidatedReportData buildConsolidatedReport({
    required String groupId,
    String? sessionId,
    DateTime? startDate,
    DateTime? endDate,
    String? studentQuery,
  }) {
    final group = _groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => _groups.first,
    );

    // 1. Filtrar sesiones en el alcance
    var sessions = getSessionsForGroup(group.id).where((s) {
      if (sessionId != null && sessionId.isNotEmpty && s.id != sessionId) {
        return false;
      }
      if (startDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        if (s.date.isBefore(start)) return false;
      }
      if (endDate != null) {
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        if (s.date.isAfter(end)) return false;
      }
      return true;
    }).toList();

    final sessionIds = sessions.map((s) => s.id).toSet();

    // 2. Filtrar estudiantes del grupo
    final query = studentQuery?.trim().toLowerCase() ?? '';
    final students = getStudentsForGroup(group.id).where((st) {
      if (query.isEmpty) return true;
      return st.fullName.toLowerCase().contains(query) ||
          st.senatiCode.toLowerCase().contains(query);
    }).toList();

    // 3. Calcular consolidado por estudiante y verificar contra registros de origen
    var rawAttendanceCount = 0;
    var rawPointsSum = 0;

    final rows = <ConsolidatedStudentRow>[];
    for (final st in students) {
      var p = 0, t = 0, f = 0, j = 0;
      for (final sesId in sessionIds) {
        final status = getAttendance(sesId, st.id);
        rawAttendanceCount++;
        switch (status) {
          case AttendanceStatus.present:
            p++;
            break;
          case AttendanceStatus.late:
            t++;
            break;
          case AttendanceStatus.absent:
            f++;
            break;
          case AttendanceStatus.excused:
            j++;
            break;
        }
      }

      // Si se filtra por una sesión o rango de fechas, sumamos las transacciones de esas sesiones;
      // si es el consolidado general sin transacciones puntuales previas, incluimos el acumulado base.
      final sessionTransactions = _pointTransactions
          .where((tx) => sessionIds.contains(tx.sessionId) && tx.studentId == st.id)
          .toList();

      final int pointsForScope;
      if (sessionId != null && sessionId.isNotEmpty) {
        final basePts = getStudentPoints(st.id);
        final txSum = sessionTransactions.fold<int>(0, (s, e) => s + e.delta);
        pointsForScope = txSum != 0 ? txSum : basePts;
      } else {
        pointsForScope = getStudentPoints(st.id);
      }
      rawPointsSum += pointsForScope;

      rows.add(
        ConsolidatedStudentRow(
          codigoInstitucional: st.senatiCode,
          nombresCompletos: st.fullName,
          presentes: p,
          tardanzas: t,
          faltas: f,
          justificados: j,
          totalAsistencias: p + t + f + j,
          totalPuntos: pointsForScope,
        ),
      );
    }

    final consolidatedPoints = rows.fold<int>(0, (s, r) => s + r.totalPuntos);
    final consolidatedAttendances =
        rows.fold<int>(0, (s, r) => s + r.totalAsistencias);
    final integrityVerified = (consolidatedPoints == rawPointsSum) &&
        (consolidatedAttendances == rawAttendanceCount);

    // 4. Metadatos de cabecera obligatorios
    final String scopeLabel;
    if (sessionId != null && sessionId.isNotEmpty && sessions.length == 1) {
      final s = sessions.first;
      scopeLabel = 'Sesión N° ${s.sessionNumber}: ${s.topic} (${s.formattedDate})';
    } else {
      scopeLabel = '${group.semester} (${sessions.length} sesiones consolidadas)';
    }

    final criteria = <String>['Grupo: ${group.nrcCode}'];
    if (sessionId != null && sessionId.isNotEmpty && sessions.length == 1) {
      criteria.add('Sesión N° ${sessions.first.sessionNumber}');
    } else {
      criteria.add('Todas las sesiones');
    }
    if (startDate != null) {
      criteria.add(
        'Desde: ${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}',
      );
    }
    if (endDate != null) {
      criteria.add(
        'Hasta: ${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
      );
    }
    if (query.isNotEmpty) {
      criteria.add('Alumno: "$studentQuery"');
    }

    return ConsolidatedReportData(
      grupoCodigo: group.nrcCode,
      grupoNombre: group.courseName,
      periodo: group.semester,
      sesionOAlcance: scopeLabel,
      fechaGeneracion: DateTime.now(),
      criteriosFiltroAplicados: criteria.join(' | '),
      integridadVerificada: integrityVerified,
      totalPuntosConsolidado: consolidatedPoints,
      totalAsistenciasConsolidado: consolidatedAttendances,
      estudiantes: rows,
    );
  }
}
