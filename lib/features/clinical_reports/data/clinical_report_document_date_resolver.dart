import '../models/clinical_report.dart';
import '../../pdf_outputs/services/templates/clinical_document_pdf_helpers.dart';

abstract final class ClinicalReportDocumentDateResolver {
  static String resolveLabel({
    required ClinicalReport report,
    required DateTime generatedAt,
    DateTime? encounterDate,
  }) {
    final date = resolveDate(
      report: report,
      generatedAt: generatedAt,
      encounterDate: encounterDate,
    );
    return formatClinicalDocDate(date);
  }

  static DateTime resolveDate({
    required ClinicalReport report,
    required DateTime generatedAt,
    DateTime? encounterDate,
  }) {
    if (report.documentDateSource ==
            ClinicalReportDocumentDateSource.muayeneTarihi &&
        encounterDate != null) {
      return encounterDate;
    }
    return report.createdAt;
  }
}
