import '../models/pdf_output.dart';
import 'async_pdf_output_repository_contract.dart';
import 'pdf_output_repository_failure.dart';

/// Supabase PDF çıktı repository — remote gate kapalıyken güvenli notConfigured.
class SupabaseAsyncPdfOutputRepositoryStub
    implements AsyncPdfOutputRepositoryContract {
  const SupabaseAsyncPdfOutputRepositoryStub();

  static Never _notReady() {
    throw const PdfOutputRepositoryException(
      PdfOutputRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<PdfOutput>> getAll() async => _notReady();

  @override
  Future<List<PdfOutput>> getByPatientId(String patientId) async => _notReady();

  @override
  Future<PdfOutput?> getById(String id) async => _notReady();

  @override
  Future<List<PdfOutput>> search(String query) async => _notReady();
}
