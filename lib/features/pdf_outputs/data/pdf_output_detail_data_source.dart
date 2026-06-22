import '../../../core/data/repository_registry.dart';
import '../models/pdf_output.dart';
import 'pdf_output_repository_failure.dart';

/// PDF çıktı detay — async registry hattı.
abstract final class PdfOutputDetailDataSource {
  static Future<PdfOutput?> loadById(String id) async {
    try {
      return await RepositoryRegistry.pdfOutputsAsync.getById(id);
    } on PdfOutputRepositoryException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
