import 'package:flutter/material.dart';
import '../../core/theme/senati_theme.dart';
import '../controllers/app_controller.dart';

class DashboardScreen extends StatelessWidget {
  final AppController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructorBanner(context),
          const SizedBox(height: 20),
          _buildMetricsRow(context),
          const SizedBox(height: 24),
          const Text(
            'Accesos Rápidos del Instructor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: SenatiTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Seleccione un módulo para gestionar su clase con el mínimo de clics.',
            style: TextStyle(
              fontSize: 13,
              color: SenatiTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _buildQuickActionsGrid(context),
          const SizedBox(height: 24),
          _buildActiveGroupsPreview(context),
        ],
      ),
    );
  }

  Widget _buildInstructorBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SenatiTheme.primaryBlue, SenatiTheme.secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${controller.zonalCampus} • ${controller.instructorCode}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bienvenido, ${controller.instructorName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Grupo activo: ${controller.selectedGroup.nrcCode} - ${controller.selectedGroup.courseName}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 680;
        final items = [
          _MetricTile(
            label: 'Grupos',
            value: '${controller.groups.length}',
            subtitle: 'Semestre 2026-II',
            icon: Icons.groups_rounded,
            color: SenatiTheme.primaryBlue,
          ),
          _MetricTile(
            label: 'Sesiones',
            value: '${controller.totalSessionsCount}',
            subtitle: 'Registradas',
            icon: Icons.event_note_rounded,
            color: SenatiTheme.secondaryBlue,
          ),
          _MetricTile(
            label: 'Estudiantes',
            value: '${controller.totalStudentsCount}',
            subtitle: 'En 4 bloques NRC',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF0D9488),
          ),
          _MetricTile(
            label: 'Pendientes Sync',
            value: '${controller.pendingSyncCount}',
            subtitle: controller.isOnline ? 'Sincronizado' : 'Guardado local',
            icon: Icons.sync_rounded,
            color: controller.pendingSyncCount > 0
                ? SenatiTheme.accentAmber
                : SenatiTheme.statusPresent,
          ),
        ];

        if (isMobile) {
          return GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 88,
            ),
            itemBuilder: (context, idx) => items[idx],
          );
        }

        return Row(
          children: items
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: item,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final cards = [
      _QuickActionCard(
        title: 'Gestionar Grupos',
        subtitle: 'Ver bloques NRC asignados, historial de sesiones y crear nueva sesión.',
        badgeText: '${controller.groups.length} Grupos',
        icon: Icons.class_rounded,
        accentColor: SenatiTheme.primaryBlue,
        onTap: () => controller.navigateTo(1),
      ),
      _QuickActionCard(
        title: 'Control de Asistencia',
        subtitle: 'Marcar Presente, Tardanza, Falta o Justificado con 1 clic por alumno.',
        badgeText: 'Registro Ágil',
        icon: Icons.fact_check_rounded,
        accentColor: SenatiTheme.statusPresent,
        onTap: () => controller.navigateTo(2),
      ),
      _QuickActionCard(
        title: 'Puntuación Rápida',
        subtitle: 'Asignar puntos (+1, +2, -1) por participación y ver el acumulado en vivo.',
        badgeText: 'Tiempo Real',
        icon: Icons.stars_rounded,
        accentColor: SenatiTheme.accentAmber,
        onTap: () => controller.navigateTo(3),
      ),
      _QuickActionCard(
        title: 'Reportes y PDF',
        subtitle: 'Filtrar por grupo/sesión y exportar consolidados a PDF o Excel.',
        badgeText: 'Exportación',
        icon: Icons.picture_as_pdf_rounded,
        accentColor: const Color(0xFF7C3AED),
        onTap: () => controller.navigateTo(4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 195,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildActiveGroupsPreview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grupos Asignados del Instructor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: SenatiTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Acceda directamente a las sesiones, asistencia o puntos de cualquier bloque.',
                        style: TextStyle(
                          fontSize: 12,
                          color: SenatiTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => controller.navigateTo(1),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Ver todos'),
                ),
              ],
            ),
            const Divider(height: 20),
            ...controller.groups.map((group) {
              final sessionsCount = controller.getSessionsForGroup(group.id).length;
              final studentsCount = controller.getStudentsForGroup(group.id).length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SenatiTheme.backgroundGrey,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SenatiTheme.borderGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: SenatiTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.courseName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: SenatiTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.career} • ${group.schedule} • $studentsCount alumnos • $sessionsCount sesiones',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: SenatiTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  controller.navigateTo(2, groupId: group.id),
                              icon: const Icon(Icons.fact_check_outlined, size: 16),
                              label: const Text('Asistencia'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  controller.navigateTo(3, groupId: group.id),
                              icon: const Icon(Icons.stars_rounded, size: 16),
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

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: SenatiTheme.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: SenatiTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: SenatiTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
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
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SenatiTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: SenatiTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: SenatiTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Abrir módulo',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: accentColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
