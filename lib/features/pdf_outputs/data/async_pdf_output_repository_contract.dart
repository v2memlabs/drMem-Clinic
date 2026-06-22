import '../models/pdf_output.dart';

/// Async PDF çıktı repository — liste/detay remote yansıma.
abstract interface class AsyncPdfOutputRepositoryContract {
  Future<List<PdfOutput>> getAll();

  Future<List<PdfOutput>> getByPatientId(String patientId);

  Future<PdfOutput?> getById(String id);

  Future<List<PdfOutput>> search(String query);
}
