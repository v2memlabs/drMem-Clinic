import '../../../core/data/repository_registry.dart';
import 'async_patient_repository_contract.dart';
import 'patient_list_load_result.dart';
import 'patient_list_user_messages.dart';
import 'patient_repository_failure.dart';

/// Hasta listesi veri kaynağı — [RepositoryRegistry.patientsAsync].
abstract final class PatientListDataSource {
  static const int defaultPageSize = 50;

  static Future<PatientListLoadResult> load(
    String query, {
    PatientListPageCursor? after,
    int limit = defaultPageSize,
  }) async {
    try {
      final repo = RepositoryRegistry.patientsAsync;
      final page = await repo.listPage(
        query: query,
        after: after,
        limit: limit,
      );
      return PatientListLoadResult.success(
        page.patients,
        nextCursor: page.nextCursor,
      );
    } on PatientRepositoryException catch (e) {
      return PatientListLoadResult.failure(
        PatientListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PatientListLoadResult.failure(
        PatientListUserMessages.genericLoadFailure,
      );
    }
  }
}
