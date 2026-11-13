import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Guarda los bytes generados (PDF o Excel) en el sistema de archivos local del dispositivo.
class FileStorageHelper {
  static Future<String> saveReportBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      // En Flutter Web no existe sistema de archivos nativo directo; devolvemos ruta virtual.
      return 'Descargas/$fileName (${bytes.length} bytes)';
    }

    Directory directory;
    if (Platform.isAndroid) {
      // En Android intentamos usar directamente la carpeta pública "Download"
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        directory = downloadDir;
      } else {
        final externalDirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (externalDirs != null && externalDirs.isNotEmpty) {
          directory = externalDirs.first;
        } else {
          directory =
              await getExternalStorageDirectory() ??
              await getApplicationDocumentsDirectory();
        }
      }
    } else {
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (_) {
        directory = Directory.systemTemp;
      }
    }

    final reportsDir = Directory(p.join(directory.path, 'AulaPuntosReports'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final filePath = p.join(reportsDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
