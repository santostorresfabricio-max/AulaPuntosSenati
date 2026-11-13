import 'package:flutter/material.dart';
import '../../core/theme/senati_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/export/excel_export_service.dart';
import '../../data/export/pdf_export_service.dart';
import '../../domain/entities/report_models.dart';
import '../controllers/app_controller.dart';

class ReportsExportScreen extends StatefulWidget {
  final AppController controller;

  const ReportsExportScreen({super.key, required this.controller});

  @override
  State<ReportsExportScreen> createState() => _ReportsExportScreenState();
}

class _ReportsExportScreenState extends State<ReportsExportScreen> {
  final PdfExportService _pdfExportService = PdfExportService();
  final ExcelExportService _excelExportService = ExcelExportService();

  /// null o '' representa "Todas las sesiones (Consolidado del periodo)"
  String _selectedSessionFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _studentQuery = '';
  bool _isExporting = false;

  String _formatShortDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime(2026, 11, 1),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime(2026, 11, 30),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _handleExportPdf(ConsolidatedReportData report) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final savedPath = await _pdfExportService.exportToFile(report);
      if (!mounted) return;
      AppFeedback.showInfoNotification(
        context,
        title: 'PDF Oficial Generado (${report.grupoCodigo})',
        message: 'Guardado localmente en: $savedPath',
        icon: Icons.picture_as_pdf_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showInfoNotification(
        context,
        title: 'Error al exportar PDF',
        message: e.toString(),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportExcel(ConsolidatedReportData report) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final savedPath = await _excelExportService.exportToFile(report);
      if (!mounted) return;
      AppFeedback.showInfoNotification(
        context,
        title: 'Excel (.xlsx) Generado (${report.grupoCodigo})',
        message: 'Listo para compartir. Guardado en: $savedPath',
        icon: Icons.table_view_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showInfoNotification(
        context,
        title: 'Error al exportar Excel',
        message: e.toString(),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final group = widget.controller.selectedGroup;
    final sessions = widget.controller.getSessionsForGroup(group.id);

    // Si la sesión seleccionada no pertenece al grupo actual, volvemos a "Todas"
    final validSessionIds = sessions.map((s) => s.id).toSet();
    final effectiveSessionId =
        validSessionIds.contains(_selectedSessionFilter)
            ? _selectedSessionFilter
            : '';

    final report = widget.controller.buildConsolidatedReport(
      groupId: group.id,
      sessionId: effectiveSessionId.isEmpty ? null : effectiveSessionId,
      startDate: _startDate,
      endDate: _endDate,
      studentQuery: _studentQuery,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera y Botones Conectados a PdfExportService y ExcelExportService
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
                    'Reportes Consolidados y Exportación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: SenatiTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Filtre por grupo, sesión, rango de fechas o alumno y exporte el acta a PDF o Excel.',
                    style: TextStyle(
                      fontSize: 13,
                      color: SenatiTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isExporting ? null : () => _handleExportPdf(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Exportar PDF'),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _isExporting ? null : () => _handleExportExcel(report),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.table_chart_rounded, size: 18),
                    label: const Text('Exportar a Excel'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Controles de Filtro: Grupo, Sesión, Rango de Fechas y Estudiante
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: group.id,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Grupo (NRC)',
                      prefixIcon: Icon(Icons.filter_alt_outlined),
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
                        setState(() => _selectedSessionFilter = '');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: effectiveSessionId,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Sesión o Consolidado',
                      prefixIcon: Icon(Icons.event_note_outlined),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text(
                          'Todas las sesiones (Consolidado del periodo)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...sessions.map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            'Sesión ${s.sessionNumber} (${s.formattedDate}) - ${s.topic}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSessionFilter = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickStartDate,
                          icon: const Icon(Icons.date_range_rounded, size: 16),
                          label: Text(
                            _startDate == null
                                ? 'Desde fecha'
                                : 'Desde: ${_formatShortDate(_startDate!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickEndDate,
                          icon: const Icon(Icons.event_available_rounded, size: 16),
                          label: Text(
                            _endDate == null
                                ? 'Hasta fecha'
                                : 'Hasta: ${_formatShortDate(_endDate!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_startDate != null || _endDate != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Limpiar fechas',
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear_rounded, size: 20),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _studentQuery = v),
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por estudiante (Código o Apellidos)',
                      prefixIcon: Icon(Icons.person_search_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vista Previa del Reporte Consolidado con Cabecera Obligatoria
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTA CONSOLIDADA • ${report.grupoCodigo} - ${report.grupoNombre}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: SenatiTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Alcance: ${report.sesionOAlcance}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: SenatiTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Filtros aplicados: ${report.criteriosFiltroAplicados}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: SenatiTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: report.integridadVerificada
                              ? SenatiTheme.statusPresent.withValues(alpha: 0.12)
                              : SenatiTheme.statusLate.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: report.integridadVerificada
                                  ? SenatiTheme.statusPresent
                                  : SenatiTheme.statusLate,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Verificado • ${report.totalPuntosConsolidado} pts',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  color: report.integridadVerificada
                                      ? SenatiTheme.statusPresent
                                      : SenatiTheme.statusLate,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: isWide ? 820 : 560,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          SenatiTheme.backgroundGrey,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'ID SENATI',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'APELLIDOS Y NOMBRES',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'P / T / F / J',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'TOTAL ASIST.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            numeric: true,
                            label: Text(
                              'TOTAL PUNTOS',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                        rows: report.estudiantes.map((student) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  student.codigoInstitucional,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  student.nombresCompletos,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${student.presentes}P • ${student.tardanzas}T • ${student.faltas}F • ${student.justificados}J',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: SenatiTheme.textSecondary,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${student.totalAsistencias}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: SenatiTheme.lightBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${student.totalPuntos} pts',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: SenatiTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
