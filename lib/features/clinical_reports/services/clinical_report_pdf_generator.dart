import '../../pdf_outputs/services/pdf_generate_result.dart';
import '../../pdf_outputs/services/pdf_letterhead_loader.dart';
import '../models/clinical_report.dart';
import 'clinical_report_pdf_template.dart';

class ClinicalReportPdfGenerator {
  ClinicalReportPdfGenerator._();

  static final ClinicalReportPdfGenerator instance =
      ClinicalReportPdfGenerator._();

  Future<PdfGenerateResult> generate({
    required ClinicalReport report,
    String? patientIdentityNumber,
    String? clinicalEncounterProtocolNumber,
    DateTime? encounterDate,
  }) async {
    final letterhead = await PdfLetterheadLoader.load(
      generatedBy: report.createdBy,
    );

    final protocolNumber =
        clinicalEncounterProtocolNumber?.trim().isNotEmpty == true
            ? clinicalEncounterProtocolNumber!.trim()
            : report.displayProtocolNumber;

    final bytes = await buildClinicalReportPdf(
      report: report,
      letterhead: letterhead,
      patientIdentityNumber: patientIdentityNumber,
      clinicalEncounterProtocolNumber: protocolNumber,
      encounterDate: encounterDate,
    );

    final typePart = report.reportType.name;
    final safeName = report.patientName
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final datePart = _formatDateForFile(letterhead.generatedAt);
    final fileName = 'rapor_${typePart}_${safeName}_$datePart.pdf';

    return PdfGenerateResult(
      bytes: bytes,
      fileName: fileName,
      generatedAt: letterhead.generatedAt,
    );
  }

  String _formatDateForFile(DateTime date) {
    final local = date.toLocal();
    return '${local.year}${local.month.toString().padLeft(2, '0')}${local.day.toString().padLeft(2, '0')}';
  }
}
