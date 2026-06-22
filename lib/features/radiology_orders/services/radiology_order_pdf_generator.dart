import '../../pdf_outputs/services/pdf_generate_result.dart';
import '../../pdf_outputs/services/pdf_letterhead_loader.dart';
import '../models/radiology_order.dart';
import 'radiology_order_pdf_template.dart';

class RadiologyOrderPdfGenerator {
  RadiologyOrderPdfGenerator._();
  static final RadiologyOrderPdfGenerator instance =
      RadiologyOrderPdfGenerator._();

  Future<PdfGenerateResult> generate({
    required RadiologyOrder order,
    String? patientIdentityNumber,
    String? patientFileNumber,
    String? clinicalEncounterProtocolNumber,
  }) async {
    final letterhead = await PdfLetterheadLoader.load(
      generatedBy: order.createdBy,
    );

    final protocolNumber =
        clinicalEncounterProtocolNumber?.trim().isNotEmpty == true
            ? clinicalEncounterProtocolNumber!.trim()
            : order.displayProtocolNumber;

    final bytes = await buildRadiologyOrderPdf(
      order: order,
      letterhead: letterhead,
      patientIdentityNumber: patientIdentityNumber,
      clinicalEncounterProtocolNumber: protocolNumber,
    );
    final datePart = _formatDate(letterhead.generatedAt);
    return PdfGenerateResult(
      bytes: bytes,
      fileName: 'radyoloji_istem_${order.patientName}_$datePart.pdf',
      generatedAt: letterhead.generatedAt,
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}${local.month.toString().padLeft(2, '0')}${local.day.toString().padLeft(2, '0')}';
  }
}