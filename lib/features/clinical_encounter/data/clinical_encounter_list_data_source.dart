import '../../../core/data/repository_registry.dart';
import '../../audit/access/clinical_access_audit_logger.dart';
import '../models/clinical_encounter.dart';
import 'clinical_encounter_list_filters.dart';
import 'clinical_encounter_list_load_result.dart';
import 'clinical_encounter_list_user_messages.dart';
import 'clinical_encounter_repository_failure.dart';

/// Muayene listesi — [RepositoryRegistry.clinicalEncountersAsync].
abstract final class ClinicalEncounterListDataSource {
  static Future<ClinicalEncounterListLoadResult> load({
    String? patientId,
    required String search,
    required bool usesRemote,
  }) async {
    try {
      final repo = RepositoryRegistry.clinicalEncountersAsync;
      final q = search.trim();
      final hasPatient = patientId != null && patientId.isNotEmpty;

      List<ClinicalEncounter> list;

      if (q.isNotEmpty) {
        if (usesRemote) {
          list = await repo.search(q);
        } else {
          final base = hasPatient
              ? await repo.getByPatientId(patientId)
              : await repo.getAll();
          list = ClinicalEncounterListFilters.applyMockSearch(base, q);
        }
        if (hasPatient) {
          list = list.where((e) => e.patientId == patientId).toList();
        }
      } else if (hasPatient) {
        list = await repo.getByPatientId(patientId);
      } else {
        list = await repo.getAll();
      }

      ClinicalAccessAuditLogger.clinicalFullList(
        patientId: patientId,
        resultCount: list.length,
      );
      return ClinicalEncounterListLoadResult.success(list);
    } on ClinicalEncounterRepositoryException catch (e) {
      final category = ClinicalAccessAuditLogger.categoryForClinicalFailure(
        e.reason,
      );
      if (e.reason == ClinicalEncounterRepositoryFailure.forbidden) {
        ClinicalAccessAuditLogger.permissionDenied(
          attemptedEventType: 'clinical.full.list',
          failureCategory: category,
        );
      }
      ClinicalAccessAuditLogger.clinicalFullList(
        patientId: patientId,
        success: false,
        failureCategory: category,
      );
      return ClinicalEncounterListLoadResult.failure(
        ClinicalEncounterListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      ClinicalAccessAuditLogger.clinicalFullList(
        patientId: patientId,
        success: false,
        failureCategory: 'unknown',
      );
      return ClinicalEncounterListLoadResult.failure(
        ClinicalEncounterListUserMessages.genericLoadFailure,
      );
    }
  }
}
