import '../../pdf_outputs/services/pdf_generate_result.dart';
import '../../pdf_outputs/services/pdf_letterhead_loader.dart';
import '../models/lab_order.dart';
import 'lab_order_pdf_template.dart';

class LabOrderPdfGenerator {
  LabOrderPdfGenerator._();
  static final LabOrderPdfGenerator instance = LabOrderPdfGenerator._();

  Future<PdfGenerateResult> generate({
    required LabOrder order,
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

    final bytes = await buildLabOrderPdf(
      order: order,
      letterhead: letterhead,
      patientIdentityNumber: patientIdentityNumber,
      clinicalEncounterProtocolNumber: protocolNumber,
    );
    final datePart = _formatDate(letterhead.generatedAt);
    return PdfGenerateResult(
      bytes: bytes,
      fileName: 'lab_istem_${order.patientName}_$datePart.pdf',
      generatedAt: letterhead.generatedAt,
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}${local.month.toString().padLeft(2, '0')}${local.day.toString().padLeft(2, '0')}';
  }
}