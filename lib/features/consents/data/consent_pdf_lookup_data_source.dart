import '../../../core/data/repository_registry.dart';
import '../../pdf_outputs/models/pdf_output.dart';
import '../models/consent_record.dart';

/// Onam kaydına bağlı PDF çıktısını bulur.
abstract final class ConsentPdfLookupDataSource {
  static Future<PdfOutput?> findPdfForConsent(ConsentRecord consent) async {
    final directId = consent.pdfOutputId?.trim();
    if (directId != null && directId.isNotEmpty) {
      return RepositoryRegistry.pdfOutputsAsync.getById(directId);
    }

    final records =
        await RepositoryRegistry.pdfOutputsAsync.getByPatientId(consent.patientId);
    for (final output in records) {
      if (output.sourceModule != pdfSourceModuleConsentTemplate) continue;
      if (output.sourceRecordId?.trim() == consent.id) return output;
    }
    return null;
  }
}
