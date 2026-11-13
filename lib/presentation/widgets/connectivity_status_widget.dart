import 'package:flutter/material.dart';
import '../../core/utils/app_feedback.dart';
import '../controllers/app_controller.dart';

class ConnectivityStatusWidget extends StatelessWidget {
  final AppController controller;

  const ConnectivityStatusWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = controller.isOnline;

    return Tooltip(
      message: isOnline
          ? 'En línea (Online) • Toque para simular Offline'
          : 'Sin conexión (Offline) • Toque para reconectar',
      child: InkWell(
        onTap: () {
          final previousPending = controller.pendingSyncCount;
          controller.toggleConnectivity();
          if (controller.isOnline) {
            AppFeedback.showInfoNotification(
              context,
              title: 'Conexión Restablecida (Online)',
              message: previousPending > 0
                  ? 'Se sincronizaron $previousPending registros pendientes.'
                  : 'Sincronización activa con el servidor SENATI.',
              icon: Icons.cloud_done_rounded,
            );
          } else {
            AppFeedback.showSaveNotification(
              context,
              isOnline: false,
              actionDescription:
                  'Modo Offline activo. Los cambios se guardarán localmente.',
              pendingSyncCount: controller.pendingSyncCount,
            );
          }
        },
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline
                  ? const Color(0xFF22C55E) // Verde (Online)
                  : const Color(0xFFEF4444), // Rojo (Offline)
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isOnline
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444))
                      .withValues(alpha: 0.55),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
