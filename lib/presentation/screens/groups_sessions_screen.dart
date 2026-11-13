import 'package:flutter/material.dart';
import '../../core/theme/senati_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../domain/entities/models.dart';
import '../controllers/app_controller.dart';

class GroupsSessionsScreen extends StatefulWidget {
  final AppController controller;

  const GroupsSessionsScreen({super.key, required this.controller});

  @override
  State<GroupsSessionsScreen> createState() => _GroupsSessionsScreenState();
}

class _GroupsSessionsScreenState extends State<GroupsSessionsScreen> {
  GroupEntity? _viewingGroupChild;

  @override
  Widget build(BuildContext context) {
    if (_viewingGroupChild != null) {
      return _GroupSessionsDetailView(
        controller: widget.controller,
        group: _viewingGroupChild!,
        onBack: () {
          setState(() {
            _viewingGroupChild = null;
          });
        },
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Grupos Asignados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: SenatiTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seleccione un grupo para ver sus sesiones o crear una nueva sesión.',
                    style: TextStyle(
                      fontSize: 13,
                      color: SenatiTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SenatiTheme.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.controller.groups.length} Bloques Activos',
                  style: const TextStyle(
                    color: SenatiTheme.primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 2 : 1;
              return GridView.builder(
                itemCount: widget.controller.groups.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 235,
                ),
                itemBuilder: (context, index) {
                  final group = widget.controller.groups[index];
                  final sessions =
                      widget.controller.getSessionsForGroup(group.id);
                  final students =
                      widget.controller.getStudentsForGroup(group.id);

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        widget.controller.selectGroup(group.id);
                        setState(() {
                          _viewingGroupChild = group;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SenatiTheme.primaryBlue,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        group.nrcCode,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${group.semester} • ${group.classroom}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: SenatiTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  group.courseName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: SenatiTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.career} • ${group.schedule}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SenatiTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMiniChip(
                                      Icons.people_alt_outlined,
                                      '${students.length} Alumnos',
                                    ),
                                    const SizedBox(width: 10),
                                    _buildMiniChip(
                                      Icons.event_note_outlined,
                                      '${sessions.length} Sesiones',
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    widget.controller.selectGroup(group.id);
                                    setState(() {
                                      _viewingGroupChild = group;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.folder_open_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Sesiones'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: SenatiTheme.primaryBlue),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SenatiTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _GroupSessionsDetailView extends StatefulWidget {
  final AppController controller;
  final GroupEntity group;
  final VoidCallback onBack;

  const _GroupSessionsDetailView({
    required this.controller,
    required this.group,
    required this.onBack,
  });

  @override
  State<_GroupSessionsDetailView> createState() =>
      _GroupSessionsDetailViewState();
}

class _GroupSessionsDetailViewState extends State<_GroupSessionsDetailView> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  DateTime _selectedDate = DateTime(2026, 11, 13);
  SessionType _selectedType = SessionType.laboratorio;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleCreateSession() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final created = widget.controller.createSession(
      groupId: widget.group.id,
      topic: _topicController.text,
      date: _selectedDate,
      type: _selectedType,
    );

    _topicController.clear();
    setState(() {});

    AppFeedback.showSaveNotification(
      context,
      isOnline: widget.controller.isOnline,
      actionDescription:
          'Sesión N° ${created.sessionNumber} "${created.topic}" creada con éxito.',
      pendingSyncCount: widget.controller.pendingSyncCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 950;
    final sessions = widget.controller.getSessionsForGroup(widget.group.id);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Volver'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.group.nrcCode} • ${widget.group.courseName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SenatiTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildQuickCreateSessionCard(),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 7,
                  child: _buildSessionsListCard(sessions),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildQuickCreateSessionCard(),
                const SizedBox(height: 18),
                _buildSessionsListCard(sessions),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickCreateSessionCard() {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final year = _selectedDate.year;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SenatiTheme.lightBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_task_rounded,
                      color: SenatiTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear Nueva Sesión Rápida',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: SenatiTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Habilita de inmediato la asistencia y puntos',
                          style: TextStyle(
                            fontSize: 12,
                            color: SenatiTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Tema de la Sesión',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SenatiTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Consumo de APIs y manejo de estados',
                  prefixIcon: Icon(Icons.topic_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingrese el tema de la sesión';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Tipo de Sesión',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SenatiTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<SessionType>(
                isExpanded: true,
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: SessionType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'Fecha de la Sesión',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SenatiTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Text(
                          '$day/$month/$year',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: SenatiTheme.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.edit_calendar_rounded,
                          size: 18,
                          color: SenatiTheme.primaryBlue,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _handleCreateSession,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('GUARDAR NUEVA SESIÓN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsListCard(List<SessionEntity> sessions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Sesiones del Grupo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: SenatiTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SenatiTheme.lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${sessions.length} registradas',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: SenatiTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No hay sesiones registradas para este grupo.'),
                ),
              )
            else
              ...sessions.reversed.map((session) {
                final summary = widget.controller.getAttendanceSummary(
                  session.id,
                  widget.group.id,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SenatiTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SenatiTheme.borderGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: SenatiTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SESIÓN N° ${session.sessionNumber} • ${session.type.label.toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.event_rounded,
                                  size: 14,
                                  color: SenatiTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  session.formattedDate,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: SenatiTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session.topic,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: SenatiTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Asistencia: ${summary[AttendanceStatus.present]} P • ${summary[AttendanceStatus.late]} T • ${summary[AttendanceStatus.absent]} F • ${summary[AttendanceStatus.excused]} J',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: SenatiTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  widget.controller.navigateTo(
                                    2,
                                    groupId: widget.group.id,
                                    sessionId: session.id,
                                  );
                                },
                                icon: const Icon(
                                  Icons.fact_check_outlined,
                                  size: 16,
                                ),
                                label: const Text('Asistencia'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  widget.controller.navigateTo(
                                    3,
                                    groupId: widget.group.id,
                                    sessionId: session.id,
                                  );
                                },
                                icon: const Icon(
                                  Icons.stars_rounded,
                                  size: 16,
                                ),
                                label: const Text('Puntos'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
