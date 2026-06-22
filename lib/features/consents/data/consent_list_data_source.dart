import '../../../core/data/repository_registry.dart';
import '../models/consent_record.dart';
import 'consent_list_filters.dart';
import 'consent_list_load_result.dart';
import 'consent_list_user_messages.dart';
import 'consent_repository_failure.dart';

abstract final class ConsentListDataSource {
  static Future<ConsentListLoadResult> load({
    String? patientId,
    required String query,
    ConsentType? consentTypeFilter,
    ConsentStatus? statusFilter,
  }) async {
    try {
      final repo = RepositoryRegistry.consentsAsync;
      final q = query.trim().toLowerCase();
      final hasPatient = patientId != null && patientId.trim().isNotEmpty;

      List<ConsentRecord> list;
      if (q.isNotEmpty) {
        list = await repo.search(q);
        if (hasPatient) {
          list = list.where((c) => c.patientId == patientId).toList();
        }
      } else if (hasPatient) {
        list = await repo.getByPatientId(patientId!.trim());
      } else {
        list = await repo.getAll();
      }

      if (q.isNotEmpty) {
        list = list.where((c) => ConsentListFilters.matchesQuery(c, q)).toList();
      }

      list = ConsentListFilters.apply(
        items: list,
        consentTypeFilter: consentTypeFilter,
        statusFilter: statusFilter,
      );

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return ConsentListLoadResult.success(list);
    } on ConsentRepositoryException catch (e) {
      return ConsentListLoadResult.failure(
        ConsentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ConsentListLoadResult.failure(
        ConsentListUserMessages.genericLoadFailure,
      );
    }
  }
}
