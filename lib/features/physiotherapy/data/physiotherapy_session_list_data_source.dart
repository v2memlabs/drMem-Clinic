import '../../../core/data/repository_registry.dart';
import '../models/physiotherapy_session_note.dart';
import 'physiotherapy_session_list_filters.dart';
import 'physiotherapy_session_list_load_result.dart';
import 'physiotherapy_session_repository_failure.dart';
import 'physiotherapy_session_user_messages.dart';

abstract final class PhysiotherapySessionListDataSource {
  static Future<PhysiotherapySessionListLoadResult> load({
    String? patientId,
    required String query,
    ReturnToSportStage? returnToSportStageEnumFilter,
    bool? doctorNotificationNeeded,
  }) async {
    try {
      final repo = RepositoryRegistry.physiotherapySessionsAsync;
      final List<PhysiotherapySessionNote> raw;
      if (patientId != null && patientId.trim().isNotEmpty) {
        raw = await repo.getByPatientId(patientId.trim());
      } else {
        raw = await repo.getAll();
      }

      final list = PhysiotherapySessionListFilters.apply(
        items: raw,
        query: query,
        returnToSportStageEnumFilter: returnToSportStageEnumFilter,
        doctorNotificationNeeded: doctorNotificationNeeded,
      );

      return PhysiotherapySessionListLoadResult.success(list);
    } on PhysiotherapySessionRepositoryException catch (e) {
      return PhysiotherapySessionListLoadResult.failure(
        PhysiotherapySessionListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PhysiotherapySessionListLoadResult.failure(
        PhysiotherapySessionListUserMessages.genericLoadFailure,
      );
    }
  }
}
