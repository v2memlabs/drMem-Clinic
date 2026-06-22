import '../models/pdf_output.dart';
import 'async_pdf_output_repository_contract.dart';
import 'pdf_output_repository.dart';

/// Mock sync repository → async contract (anında tamamlanan Future).
class MockAsyncPdfOutputRepositoryAdapter
    implements AsyncPdfOutputRepositoryContract {
  PdfOutputRepository get _sync => PdfOutputRepository.instance;

  @override
  Future<List<PdfOutput>> getAll() async => _sync.getAll();

  @override
  Future<List<PdfOutput>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<PdfOutput?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<PdfOutput>> search(String query) async => _sync.search(query);
}
