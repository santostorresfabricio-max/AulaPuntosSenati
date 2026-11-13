import 'package:flutter/material.dart';
import '../../core/theme/senati_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../controllers/app_controller.dart';

class ParticipationPointsScreen extends StatefulWidget {
  final AppController controller;

  const ParticipationPointsScreen({super.key, required this.controller});

  @override
  State<ParticipationPointsScreen> createState() =>
      _ParticipationPointsScreenState();
}

class _ParticipationPointsScreenState extends State<ParticipationPointsScreen> {
  String _searchQuery = '';

  Future<void> _showNewActivityDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Actividad de Participación'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la actividad',
            hintText: 'Ej. Solución de caso práctico en pizarra',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, textController.text),
            child: const Text('Agregar Actividad'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      widget.controller.addCustomActivity(result);
    }
  }

  void _applyPoints({
    required String studentId,
    required String studentName,
    required String sessionId,
    required int delta,
  }) {
    final activity = widget.controller.selectedActivity;
    widget.controller.updateStudentPoints(
      studentId: studentId,
      sessionId: sessionId,
      activityName: activity,
      delta: delta,
    );

    final sign = delta > 0 ? '+$delta' : '$delta';
    final total = widget.controller.getStudentPoints(studentId);

    AppFeedback.showSaveNotification(
      context,
      isOnline: widget.controller.isOnline,
      actionDescription:
          '$sign pts a ${studentName.split(',').first} en "$activity" (Total acumulado: $total pts)',
      pendingSyncCount: widget.controller.pendingSyncCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final group = widget.controller.selectedGroup;
    final sessions = widget.controller.getSessionsForGroup(group.id);
    final activeSession = widget.controller.selectedSession;
    final students = widget.controller.getStudentsForGroup(group.id).where((s) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.fullName.toLowerCase().contains(q) ||
          s.senatiCode.toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    'Puntuación Rápida de Participación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: SenatiTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seleccione la actividad y asigne puntos (+1, +2, -1) en tiempo real con un solo toque.',
                    style: TextStyle(
                      fontSize: 13,
                      color: SenatiTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _showNewActivityDialog,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Crear Actividad'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barra de Selección: Grupo, Sesión y Actividad (isExpanded: true para móviles)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      labelText: 'Sesión Activa',
                      prefixIcon: Icon(Icons.event_note_outlined),
                    ),
                    items: sessions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              'Sesión ${s.sessionNumber}: ${s.topic}',
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
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: widget.controller.selectedActivity,
                    decoration: const InputDecoration(
                      labelText: 'Actividad Evaluada',
                      prefixIcon: Icon(Icons.stars_rounded),
                    ),
                    items: widget.controller.activities
                        .map(
                          (act) => DropdownMenuItem(
                            value: act,
                            child: Text(
                              act,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.controller.selectActivity(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: const InputDecoration(
                      labelText: 'Filtrar estudiante por apellido, nombre o ID',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Lista de Estudiantes con Botones Rápidos (+1, +2, -1) y Total Acumulado en Tiempo Real
          if (activeSession == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Seleccione una sesión activa para registrar puntos.'),
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = students[index];
                  final totalPoints =
                      widget.controller.getStudentPoints(student.id);
                  final sessionDelta = widget.controller.getSessionStudentPoints(
                    activeSession.id,
                    student.id,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 19,
                              backgroundColor: SenatiTheme.primaryBlue,
                              child: Text(
                                student.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                                      fontSize: 14,
                                      color: SenatiTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: ${student.senatiCode} • ${widget.controller.selectedActivity}',
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
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _QuickScoreButton(
                                  label: '-1',
                                  color: SenatiTheme.statusAbsent,
                                  onTap: () => _applyPoints(
                                    studentId: student.id,
                                    studentName: student.fullName,
                                    sessionId: activeSession.id,
                                    delta: -1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _QuickScoreButton(
                                  label: '+1',
                                  color: SenatiTheme.secondaryBlue,
                                  onTap: () => _applyPoints(
                                    studentId: student.id,
                                    studentName: student.fullName,
                                    sessionId: activeSession.id,
                                    delta: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _QuickScoreButton(
                                  label: '+2',
                                  color: SenatiTheme.statusPresent,
                                  onTap: () => _applyPoints(
                                    studentId: student.id,
                                    studentName: student.fullName,
                                    sessionId: activeSession.id,
                                    delta: 2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: SenatiTheme.lightBlue,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: SenatiTheme.primaryBlue
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.emoji_events_rounded,
                                        size: 14,
                                        color: SenatiTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$totalPoints pts',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          color: SenatiTheme.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    sessionDelta >= 0
                                        ? 'Hoy: +$sessionDelta'
                                        : 'Hoy: $sessionDelta',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: SenatiTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

class _QuickScoreButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickScoreButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 1.3),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}
