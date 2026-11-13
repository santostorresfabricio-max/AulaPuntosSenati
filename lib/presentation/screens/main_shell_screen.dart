import 'package:flutter/material.dart';
import '../../core/theme/senati_theme.dart';
import '../controllers/app_controller.dart';
import '../widgets/connectivity_status_widget.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import 'groups_sessions_screen.dart';
import 'participation_points_screen.dart';
import 'reports_export_screen.dart';

class MainShellScreen extends StatelessWidget {
  final AppController controller;

  const MainShellScreen({super.key, required this.controller});

  static const _destinations = [
    _NavItem('Inicio', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _NavItem('Grupos', Icons.groups_outlined, Icons.groups_rounded),
    _NavItem('Asistencia', Icons.fact_check_outlined, Icons.fact_check_rounded),
    _NavItem('Puntos', Icons.stars_outlined, Icons.stars_rounded),
    _NavItem('Reportes', Icons.assessment_outlined, Icons.assessment_rounded),
  ];

  Widget _buildCurrentBody() {
    switch (controller.selectedNavIndex) {
      case 0:
        return DashboardScreen(controller: controller);
      case 1:
        return GroupsSessionsScreen(controller: controller);
      case 2:
        return AttendanceScreen(controller: controller);
      case 3:
        return ParticipationPointsScreen(controller: controller);
      case 4:
        return ReportsExportScreen(controller: controller);
      default:
        return DashboardScreen(controller: controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: SenatiTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'AULA PUNTOS - SENATI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Gestión de Grupos, Asistencia y Participación',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Solamente el punto verde (Online) / rojo (Offline) al lado del ícono de salir
          ConnectivityStatusWidget(controller: controller),
          IconButton(
            tooltip: 'Cerrar sesión del instructor',
            onPressed: controller.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended: width >= 1180,
              backgroundColor: Colors.white,
              selectedIndex: controller.selectedNavIndex,
              onDestinationSelected: (idx) => controller.navigateTo(idx),
              selectedIconTheme: const IconThemeData(
                color: SenatiTheme.primaryBlue,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: SenatiTheme.primaryBlue,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: SenatiTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
          if (isDesktop)
            const VerticalDivider(width: 1, color: SenatiTheme.borderGrey),
          Expanded(
            child: _buildCurrentBody(),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: controller.selectedNavIndex,
              onDestinationSelected: (idx) => controller.navigateTo(idx),
              backgroundColor: Colors.white,
              indicatorColor: SenatiTheme.lightBlue,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: _destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(
                        d.selectedIcon,
                        color: SenatiTheme.primaryBlue,
                      ),
                      label: d.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavItem(this.label, this.icon, this.selectedIcon);
}
