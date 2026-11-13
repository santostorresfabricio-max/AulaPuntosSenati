/// DTO seguro y minimalista para una fila del reporte consolidado.
/// Solo expone Código Institucional, Nombres y el Total de Puntos/Asistencias.
class ConsolidatedStudentRow {
  final String codigoInstitucional;
  final String nombresCompletos;
  final int presentes;
  final int tardanzas;
  final int faltas;
  final int justificados;
  final int totalAsistencias;
  final int totalPuntos;

  const ConsolidatedStudentRow({
    required this.codigoInstitucional,
    required this.nombresCompletos,
    required this.presentes,
    required this.tardanzas,
    required this.faltas,
    required this.justificados,
    required this.totalAsistencias,
    required this.totalPuntos,
  });

  factory ConsolidatedStudentRow.fromJson(Map<String, dynamic> json) {
    return ConsolidatedStudentRow(
      codigoInstitucional: json['codigoInstitucional']?.toString() ?? '',
      nombresCompletos: json['nombresCompletos']?.toString() ?? '',
      presentes: (json['presentes'] as num?)?.toInt() ?? 0,
      tardanzas: (json['tardanzas'] as num?)?.toInt() ?? 0,
      faltas: (json['faltas'] as num?)?.toInt() ?? 0,
      justificados: (json['justificados'] as num?)?.toInt() ?? 0,
      totalAsistencias:
          (json['totalAsistenciasRegistradas'] as num?)?.toInt() ?? 0,
      totalPuntos: (json['totalPuntos'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Modelo que encapsula la cabecera obligatoria y las filas consolidadas
/// tanto para la vista previa en UI como para PdfExportService y ExcelExportService.
class ConsolidatedReportData {
  final String grupoCodigo;
  final String grupoNombre;
  final String periodo;
  final String sesionOAlcance;
  final DateTime fechaGeneracion;
  final String criteriosFiltroAplicados;
  final bool integridadVerificada;
  final int totalPuntosConsolidado;
  final int totalAsistenciasConsolidado;
  final List<ConsolidatedStudentRow> estudiantes;

  const ConsolidatedReportData({
    required this.grupoCodigo,
    required this.grupoNombre,
    required this.periodo,
    required this.sesionOAlcance,
    required this.fechaGeneracion,
    required this.criteriosFiltroAplicados,
    required this.integridadVerificada,
    required this.totalPuntosConsolidado,
    required this.totalAsistenciasConsolidado,
    required this.estudiantes,
  });

  String get formattedGenerationDate {
    final d = fechaGeneracion.day.toString().padLeft(2, '0');
    final m = fechaGeneracion.month.toString().padLeft(2, '0');
    final y = fechaGeneracion.year;
    final hh = fechaGeneracion.hour.toString().padLeft(2, '0');
    final mm = fechaGeneracion.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}
