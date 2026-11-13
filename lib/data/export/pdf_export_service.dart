import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/report_models.dart';
import 'file_storage_helper.dart';

/// Servicio de generación de reportes en formato PDF con diseño institucional SENATI.
///
/// Cumple la regla de negocio de incluir obligatoriamente en la cabecera:
/// 1. Grupo (Código NRC y Nombre del curso)
/// 2. Sesión o Periodo evaluado
/// 3. Fecha y hora de generación
/// 4. Criterios de filtro aplicados
class PdfExportService {
  static const PdfColor _senatiBlue = PdfColor.fromInt(0xFF003B7B);
  static const PdfColor _senatiLightBlue = PdfColor.fromInt(0xFFE8F1FA);
  static const PdfColor _borderGrey = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor _textMuted = PdfColor.fromInt(0xFF475569);

  /// Construye los bytes del documento PDF en memoria.
  Future<Uint8List> buildPdfBytes(ConsolidatedReportData report) async {
    final doc = pw.Document(
      title: 'Reporte Consolidado - ${report.grupoCodigo}',
      author: 'Aula Puntos - SENATI',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildMandatoryHeader(report),
        footer: (context) => _buildFooter(context, report),
        build: (context) => [
          pw.SizedBox(height: 14),
          _buildSummaryBanner(report),
          pw.SizedBox(height: 14),
          _buildStudentsTable(report),
        ],
      ),
    );

    return doc.save();
  }

  /// Genera el PDF y lo guarda en el almacenamiento local del dispositivo.
  /// Devuelve la ruta completa del archivo generado.
  Future<String> exportToFile(ConsolidatedReportData report) async {
    final bytes = await buildPdfBytes(report);
    final sanitizedCode =
        report.grupoCodigo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'Reporte_SENATI_${sanitizedCode}_$timestamp.pdf';

    return FileStorageHelper.saveReportBytes(
      bytes: bytes,
      fileName: fileName,
    );
  }

  /// Cabecera obligatoria según regla de negocio:
  /// Grupo, Sesión/Periodo, Fecha de generación y Criterios de filtro aplicados.
  pw.Widget _buildMandatoryHeader(ConsolidatedReportData report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _senatiLightBlue,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _senatiBlue, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SENATI • AULA PUNTOS - REPORTE CONSOLIDADO OFICIAL',
                style: pw.TextStyle(
                  color: _senatiBlue,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Generado: ${report.formattedGenerationDate}',
                style: pw.TextStyle(
                  color: _textDark,
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Divider(color: _borderGrey, height: 10),
          pw.Text(
            'Grupo / Curso: ${report.grupoCodigo} - ${report.grupoNombre}',
            style: pw.TextStyle(
              color: _textDark,
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Sesión / Periodo: ${report.sesionOAlcance}',
            style: const pw.TextStyle(color: _textDark, fontSize: 9.5),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Criterios de filtro aplicados: ${report.criteriosFiltroAplicados}',
            style: const pw.TextStyle(color: _textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryBanner(ConsolidatedReportData report) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Estudiantes listados: ${report.estudiantes.length}',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _textDark,
          ),
        ),
        pw.Text(
          'Asistencias contabilizadas: ${report.totalAsistenciasConsolidado}   |   Total Puntos: ${report.totalPuntosConsolidado} pts',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _senatiBlue,
          ),
        ),
      ],
    );
  }

  /// Cuerpo del PDF: Tabla de estudiantes con su código institucional, asistencias y total de puntos.
  pw.Widget _buildStudentsTable(ConsolidatedReportData report) {
    final headers = [
      'ID SENATI',
      'Apellidos y Nombres',
      'P',
      'T',
      'F',
      'J',
      'Total Puntos',
    ];

    final data = report.estudiantes.map((s) {
      return [
        s.codigoInstitucional,
        s.nombresCompletos,
        '${s.presentes}',
        '${s.tardanzas}',
        '${s.faltas}',
        '${s.justificados}',
        '${s.totalPuntos} pts',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: _borderGrey, width: 0.6),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9.5,
      ),
      headerDecoration: const pw.BoxDecoration(color: _senatiBlue),
      cellStyle: const pw.TextStyle(color: _textDark, fontSize: 9),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      columnWidths: {
        0: const pw.FixedColumnWidth(72),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(28),
        3: const pw.FixedColumnWidth(28),
        4: const pw.FixedColumnWidth(28),
        5: const pw.FixedColumnWidth(28),
        6: const pw.FixedColumnWidth(68),
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildFooter(pw.Context context, ConsolidatedReportData report) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _borderGrey, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            report.integridadVerificada
                ? 'Integridad verificada contra registros de origen'
                : 'Verificación pendiente',
            style: const pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
        ],
      ),
    );
  }
}
