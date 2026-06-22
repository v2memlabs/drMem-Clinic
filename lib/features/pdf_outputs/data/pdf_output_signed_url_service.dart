import '../../../core/auth/auth_session.dart';
import '../../patient_files/data/patient_file_storage_repository.dart';
import '../../patient_files/data/patient_file_storage_repository_provider.dart';
import 'supabase_pdf_output_repository.dart';

/// PDF çıktısı için signed URL — doctor_admin + metadata/storage path.
abstract final class PdfOutputSignedUrlService {
  static const int expiresInSeconds =
      PatientFileStorageRepository.signedUrlExpiresInSeconds;

  static Future<String> createViewUrlForPdfOutput(String pdfOutputId) async {
    if (!AuthSession.canViewPdfOutputs) {
      throw const PdfOutputSignedUrlException('Bu belgeye erişim yetkiniz yok.');
    }

    final record =
        await SupabasePdfOutputRepository.fromSupabase().getStoredRecord(
      pdfOutputId,
    );
    if (record == null) {
      throw const PdfOutputSignedUrlException('PDF kaydı bulunamadı.');
    }

    return PatientFileStorageRepositoryProvider.repository.createSignedUrl(
      bucket: record.storageBucket,
      path: record.storagePath,
      expiresInSeconds: expiresInSeconds,
    );
  }
}

class PdfOutputSignedUrlException implements Exception {
  const PdfOutputSignedUrlException(this.message);

  final String message;

  @override
  String toString() => message;
}
