import 'package:flutter/material.dart';
import '../../core/theme/senati_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../domain/entities/models.dart';
import '../controllers/app_controller.dart';

class AttendanceScreen extends StatefulWidget {
  final AppController controller;

  const AttendanceScreen({super.key, required this.controller});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _searchQuery = '';

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return SenatiTheme.statusPresent;
      case AttendanceStatus.late:
        return SenatiTheme.statusLate;
      case AttendanceStatus.absent:
        return SenatiTheme.statusAbsent;
      case AttendanceStatus.excused:
        return SenatiTheme.statusExcused;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final group = widget.controller.selectedGroup;
    final sessions = widget.controller.getSessionsForGroup(group.id);
    final activeSession = widget.controller.selectedSession;
    final allStudents = widget.controller.getStudentsForGroup(group.id);

    final filteredStudents = allStudents.where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.senatiCode.toLowerCase().contains(q);
    }).toList();

    final summary = activeSession != null
        ? widget.controller.getAttendanceSummary(activeSession.id, group.id)
        : <AttendanceStatus, int>{};

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado y Acción Masiva de 1 Clic
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control Ágil de Asistencia',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: SenatiTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Marque con un solo clic el estado de cada estudiante. Guardado instantáneo.',
                    style: TextStyle(
                      fontSize: 13,
                      color: SenatiTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (activeSession != null)
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        widget.controller.markAllAttendance(
                          sessionId: activeSession.id,
                          groupId: group.id,
                          status: AttendanceStatus.present,
                        );
                        AppFeedback.showSaveNotification(
                          context,
                          isOnline: widget.controller.isOnline,
                          actionDescription:
                              'Todos los alumnos de ${group.nrcCode} marcados como PRESENTES.',
                          pendingSyncCount: widget.controller.pendingSyncCount,
                        );
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Todos Presentes (1 Clic)'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        AppFeedback.showSaveNotification(
                          context,
                          isOnline: widget.controller.isOnline,
                          actionDescription:
                              'Planilla de asistencia de Sesión N° ${activeSession.sessionNumber} consolidada.',
                          pendingSyncCount: widget.controller.pendingSyncCount,
                        );
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Confirmar Planilla'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Filtros de Grupo y Sesión (isExpanded: true evita el desbordamiento horizontal en móviles)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: group.id,
                    decoration: const InputDecoration(
                      labelText: 'Grupo / Bloque NRC',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    items: widget.controller.groups
                        .map(
                          (g) => DropdownMenuItem(
                            value: g.id,
                            child: Text(
                              '${g.nrcCode} - ${g.courseName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.controller.selectGroup(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: activeSession?.id,
                    decoration: const InputDecoration(
                      labelText: 'Sesión de Clase',
                      prefixIcon: Icon(Icons.event_note_outlined),
                    ),
                    items: sessions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              'Sesión ${s.sessionNumber} (${s.formattedDate}) - ${s.topic}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.controller.selectSession(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      labelText: 'Buscar alumno o ID',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Resumen estadístico en tiempo real
          if (activeSession != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AttendanceStatus.values.map((st) {
                final count = summary[st] ?? 0;
                final color = _getStatusColor(st);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${st.label}: $count',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 14),

          // Lista de Estudiantes con Botones Rápidos (Presente, Tardanza, Falta, Justificado)
          if (activeSession == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Seleccione o cree una sesión para tomar asistencia.'),
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredStudents.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final currentStatus = widget.controller.getAttendance(
                    activeSession.id,
                    student.id,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: SenatiTheme.lightBlue,
                          child: Text(
                            student.initials,
                            style: const TextStyle(
                              color: SenatiTheme.primaryBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: SenatiTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${student.senatiCode}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: SenatiTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: AttendanceStatus.values.map((status) {
                            final isSelected = currentStatus == status;
                            final color = _getStatusColor(status);

                            return Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Tooltip(
                                message: status.label,
                                child: InkWell(
                                  onTap: () {
                                    widget.controller.setAttendance(
                                      sessionId: activeSession.id,
                                      studentId: student.id,
                                      status: status,
                                    );
                                    AppFeedback.showSaveNotification(
                                      context,
                                      isOnline: widget.controller.isOnline,
                                      actionDescription:
                                          '${student.fullName.split(',').first}: marcado como ${status.label.toUpperCase()}.',
                                      pendingSyncCount:
                                          widget.controller.pendingSyncCount,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color
                                          : color.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : color.withValues(alpha: 0.35),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      status.shortCode,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : color,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
