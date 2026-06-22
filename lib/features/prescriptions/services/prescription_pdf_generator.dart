import '../../pdf_outputs/services/pdf_generate_result.dart';
import '../../pdf_outputs/services/pdf_letterhead_loader.dart';
import '../models/prescription.dart';
import 'prescription_pdf_template.dart';

class PrescriptionPdfGenerator {
  PrescriptionPdfGenerator._();

  static final PrescriptionPdfGenerator instance = PrescriptionPdfGenerator._();

  Future<PdfGenerateResult> generate({
    required Prescription prescription,
    String? patientIdentityNumber,
    String? patientFileNumber,
    String? clinicalEncounterProtocolNumber,
    String? eReceteNumber,
  }) async {
    final letterhead = await PdfLetterheadLoader.load(
      generatedBy: prescription.createdBy,
    );

    final bytes = await buildPrescriptionPdf(
      prescription: prescription,
      letterhead: letterhead,
      patientIdentityNumber: patientIdentityNumber,
      clinicalEncounterProtocolNumber: clinicalEncounterProtocolNumber,
      eReceteNumber: eReceteNumber,
    );

    final safeName = prescription.patientName
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final datePart = _formatDateForFile(letterhead.generatedAt);
    final fileName = 'recete_${safeName}_$datePart.pdf';

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