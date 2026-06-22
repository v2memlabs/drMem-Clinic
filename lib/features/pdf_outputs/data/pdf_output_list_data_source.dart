import '../../../core/data/repository_registry.dart';
import '../models/pdf_output.dart';
import 'pdf_output_list_filters.dart';
import 'pdf_output_list_load_result.dart';
import 'pdf_output_list_user_messages.dart';
import 'pdf_output_repository_failure.dart';

/// PDF çıktı listesi — [RepositoryRegistry.pdfOutputsAsync].
abstract final class PdfOutputListDataSource {
  static Future<PdfOutputListLoadResult> load({
    String? patientId,
    required String query,
    DocumentType? documentTypeFilter,
    PdfStatus? statusFilter,
  }) async {
    try {
      final repo = RepositoryRegistry.pdfOutputsAsync;
      final q = query.trim();
      final hasPatient = patientId != null && patientId.isNotEmpty;

      List<PdfOutput> list;

      if (q.isNotEmpty) {
        list = await repo.search(q);
        if (hasPatient) {
          list = list.where((p) => p.patientId == patientId).toList();
        }
      } else if (hasPatient) {
        list = await repo.getByPatientId(patientId);
      } else {
        list = await repo.getAll();
      }

      list = PdfOutputListFilters.apply(
        items: list,
        documentTypeFilter: documentTypeFilter,
        statusFilter: statusFilter,
      );

      return PdfOutputListLoadResult.success(list);
    } on PdfOutputRepositoryException catch (e) {
      return PdfOutputListLoadResult.failure(
        PdfOutputListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PdfOutputListLoadResult.failure(
        PdfOutputListUserMessages.genericLoadFailure,
      );
    }
  }
}
