import 'package:excel/excel.dart';

import '../../domain/entities/report_models.dart';
import 'file_storage_helper.dart';

/// Servicio de exportación a Excel (.xlsx) con cabecera institucional obligatoria
/// y tabla consolidada lista para compartir (ej. vía WhatsApp o correo).
class ExcelExportService {
  /// Construye los bytes del archivo .xlsx en memoria.
  List<int> buildExcelBytes(ConsolidatedReportData report) {
    final excel = Excel.createExcel();
    const sheetName = 'Consolidado_SENATI';
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }

    final sheet = excel[sheetName];

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#003B7B'),
    );
    final metaLabelStyle = CellStyle(bold: true, fontSize: 10);
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#003B7B'),
    );

    // 1. Cabecera obligatoria (Grupo, Sesión/Periodo, Fecha de generación, Filtros)
    void setMetaRow(int rowIdx, String label, String value) {
      final labelCell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
      labelCell.value = TextCellValue(label);
      labelCell.cellStyle = metaLabelStyle;

      final valueCell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx));
      valueCell.value = TextCellValue(value);
    }

    final titleCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value =
        TextCellValue('SENATI - REPORTE CONSOLIDADO DE ASISTENCIA Y PUNTOS');
    titleCell.cellStyle = titleStyle;

    setMetaRow(
      1,
      'Grupo / Curso:',
      '${report.grupoCodigo} - ${report.grupoNombre}',
    );
    setMetaRow(2, 'Sesión / Periodo:', report.sesionOAlcance);
    setMetaRow(3, 'Fecha de Generación:', report.formattedGenerationDate);
    setMetaRow(4, 'Filtros Aplicados:', report.criteriosFiltroAplicados);
    setMetaRow(
      5,
      'Integridad de Totales:',
      report.integridadVerificada
          ? 'Verificada (Coincide con registros de origen)'
          : 'No verificada',
    );

    // 2. Encabezados de la tabla de estudiantes (fila índice 7)
    const headerRowIndex = 7;
    final columns = [
      'Código Institucional',
      'Apellidos y Nombres',
      'Presentes (P)',
      'Tardanzas (T)',
      'Faltas (F)',
      'Justificados (J)',
      'Total Asistencias',
      'Total Puntos',
    ];

    for (var col = 0; col < columns.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: headerRowIndex),
      );
      cell.value = TextCellValue(columns[col]);
      cell.cellStyle = headerStyle;
    }

    // 3. Cuerpo de datos (filas de estudiantes)
    var currentRow = headerRowIndex + 1;
    for (final s in report.estudiantes) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
          .value = TextCellValue(s.codigoInstitucional);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow))
          .value = TextCellValue(s.nombresCompletos);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow))
          .value = IntCellValue(s.presentes);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow))
          .value = IntCellValue(s.tardanzas);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow))
          .value = IntCellValue(s.faltas);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow))
          .value = IntCellValue(s.justificados);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow))
          .value = IntCellValue(s.totalAsistencias);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow))
          .value = IntCellValue(s.totalPuntos);
      currentRow++;
    }

    // 4. Fila final de sumatoria verificada
    final totalLabelCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow));
    totalLabelCell.value = TextCellValue('TOTALES CONSOLIDADOS');
    totalLabelCell.cellStyle = metaLabelStyle;

    final totalAsistCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow));
    totalAsistCell.value = IntCellValue(report.totalAsistenciasConsolidado);
    totalAsistCell.cellStyle = metaLabelStyle;

    final totalPtsCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: currentRow));
    totalPtsCell.value = IntCellValue(report.totalPuntosConsolidado);
    totalPtsCell.cellStyle = metaLabelStyle;

    return excel.encode() ?? <int>[];
  }

  /// Genera el archivo Excel (.xlsx) y lo guarda en el dispositivo.
  Future<String> exportToFile(ConsolidatedReportData report) async {
    final bytes = buildExcelBytes(report);
    final sanitizedCode =
        report.grupoCodigo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Reporte_SENATI_${sanitizedCode}_$timestamp.xlsx';

    return FileStorageHelper.saveReportBytes(
      bytes: bytes,
      fileName: fileName,
    );
  }
}
