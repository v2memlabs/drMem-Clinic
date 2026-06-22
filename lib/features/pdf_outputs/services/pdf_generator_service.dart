import '../../clinical_encounter/models/clinical_encounter.dart';
import '../models/pdf_output.dart';
import 'pdf_generate_result.dart';
import 'pdf_letterhead_config.dart';
import 'templates/clinical_encounter_summary_pdf_template.dart';
import 'templates/form_snapshot_pdf_template.dart';

/// Local PDF üretimi — muayene özeti template + form snapshot fallback.
class PdfGeneratorService {
  PdfGeneratorService._();

  static final PdfGeneratorService instance = PdfGeneratorService._();

  /// PdfOutput kaydından mevcut muayene template ile üretilebilir mi?
  bool canGenerateFromPdfOutput(PdfOutput output) {
    return output.documentType == DocumentType.muayeneOzeti &&
        output.sourceModule == pdfSourceModuleClinicalEncounter &&
        (output.sourceRecordId?.trim().isNotEmpty ?? false);
  }

  /// ClinicalEncounter snapshot ile Muayene Özeti PDF (sync repo lookup yok).
  Future<PdfGenerateResult> generateClinicalEncounterSummary({
    required ClinicalEncounter encounter,
    String? createdBy,
    String? warningNote,
    String? patientFileNumber,
  }) async {
    final letterhead = PdfLetterheadConfig.fromCurrentSettings(
      generatedBy: createdBy,
    );

    final bytes = await buildClinicalEncounterSummaryPdf(
      encounter: encounter,
      letterhead: letterhead,
      patientFileNumber: patientFileNumber,
      warningNote: warningNote,
    );

    final fileNo = patientFileNumber?.trim() ?? '';
    final safeName = encounter.patientName
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final datePart = _formatDateForFile(letterhead.generatedAt);
    final suffix = fileNo.isNotEmpty ? '${fileNo}_' : '';
    final fileName = 'muayene_ozeti_${suffix}${safeName}_$datePart.pdf';

    return PdfGenerateResult(
      bytes: bytes,
      fileName: fileName,
      generatedAt: letterhead.generatedAt,
    );
  }

  /// Form alanlarından minimal PDF — repository lookup yok.
  Future<PdfGenerateResult> generateFromFormSnapshot({
    required PdfOutput output,
    String? patientFileNumber,
  }) async {
    final letterhead = PdfLetterheadConfig.fromCurrentSettings(
      generatedBy: output.createdBy,
    );

    final bytes = await buildFormSnapshotPdf(
      output: output,
      letterhead: letterhead,
      patientFileNumber: patientFileNumber,
    );

    final safeTitle = output.title
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final titlePart = safeTitle.isEmpty ? 'belge' : safeTitle;
    final datePart = _formatDateForFile(letterhead.generatedAt);
    final fileName = '${titlePart}_$datePart.pdf';

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
