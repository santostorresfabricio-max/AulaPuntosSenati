enum AttendanceStatus {
  present('Presente', 'P'),
  late('Tardanza', 'T'),
  absent('Falta', 'F'),
  excused('Justificado', 'J');

  final String label;
  final String shortCode;
  const AttendanceStatus(this.label, this.shortCode);
}

enum SessionType {
  teoria('Teoría'),
  laboratorio('Laboratorio / Taller'),
  evaluacion('Evaluación Continua'),
  seminario('Seminario');

  final String label;
  const SessionType(this.label);
}

class StudentEntity {
  final String id;
  final String senatiCode;
  final String fullName;
  final String groupId;
  final String specialty;

  const StudentEntity({
    required this.id,
    required this.senatiCode,
    required this.fullName,
    required this.groupId,
    required this.specialty,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, 2).toUpperCase();
  }
}

class GroupEntity {
  final String id;
  final String nrcCode;
  final String courseName;
  final String career;
  final String semester;
  final String schedule;
  final String classroom;

  const GroupEntity({
    required this.id,
    required this.nrcCode,
    required this.courseName,
    required this.career,
    required this.semester,
    required this.schedule,
    required this.classroom,
  });
}

class SessionEntity {
  final String id;
  final String groupId;
  final int sessionNumber;
  final String topic;
  final DateTime date;
  final SessionType type;

  const SessionEntity({
    required this.id,
    required this.groupId,
    required this.sessionNumber,
    required this.topic,
    required this.date,
    required this.type,
  });

  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}

class PointTransaction {
  final String id;
  final String studentId;
  final String sessionId;
  final String activityName;
  final int delta;
  final DateTime timestamp;
  final bool synced;

  const PointTransaction({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.activityName,
    required this.delta,
    required this.timestamp,
    required this.synced,
  });
}
