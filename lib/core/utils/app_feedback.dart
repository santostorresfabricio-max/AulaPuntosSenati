import 'package:flutter/material.dart';
import '../theme/senati_theme.dart';

class AppFeedback {
  static void showSaveNotification(
    BuildContext context, {
    required bool isOnline,
    required String actionDescription,
    int? pendingSyncCount,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final Color bgColor =
        isOnline ? const Color(0xFF0F5132) : const Color(0xFF7C2D12);
    final IconData icon =
        isOnline ? Icons.cloud_done_rounded : Icons.save_as_rounded;
    final String statusPrefix = isOnline
        ? 'Sincronizado en línea'
        : 'Modo Offline • Guardado localmente';

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bgColor,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusPrefix,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOnline
                        ? actionDescription
                        : '$actionDescription (Pendiente de sincronizar${pendingSyncCount != null ? ': $pendingSyncCount' : ''})',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  static void showInfoNotification(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SenatiTheme.primaryBlue,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
