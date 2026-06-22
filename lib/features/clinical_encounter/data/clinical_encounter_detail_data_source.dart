import '../../../core/auth/auth_session.dart';
import '../../../core/data/repository_registry.dart';
import '../../audit/access/clinical_access_audit_logger.dart';
import 'clinical_encounter_detail_load_result.dart';
import 'clinical_encounter_detail_user_messages.dart';
import 'clinical_encounter_repository_failure.dart';

/// Muayene detay — [RepositoryRegistry.clinicalEncountersAsync].getById.
abstract final class ClinicalEncounterDetailDataSource {
  static Future<ClinicalEncounterDetailLoadResult> loadById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return ClinicalEncounterDetailLoadResult.notFound();
    }

    try {
      final encounter =
          await RepositoryRegistry.clinicalEncountersAsync.getById(trimmed);
      if (encounter == null) {
        return ClinicalEncounterDetailLoadResult.notFound();
      }
      ClinicalAccessAuditLogger.clinicalFullView(
        encounterId: encounter.id,
        patientId: encounter.patientId,
      );
      if (AuthSession.canViewFullClinicalEncounter &&
          encounter.internalDoctorNote.trim().isNotEmpty) {
        ClinicalAccessAuditLogger.clinicalInternalNoteView(
          encounterId: encounter.id,
          patientId: encounter.patientId,
        );
      }
      return ClinicalEncounterDetailLoadResult.success(encounter);
    } on ClinicalEncounterRepositoryException catch (e) {
      if (e.reason == ClinicalEncounterRepositoryFailure.notFound) {
        return ClinicalEncounterDetailLoadResult.notFound();
      }
      final category = ClinicalAccessAuditLogger.categoryForClinicalFailure(
        e.reason,
      );
      if (e.reason == ClinicalEncounterRepositoryFailure.forbidden) {
        ClinicalAccessAuditLogger.permissionDenied(
          attemptedEventType: 'clinical.full.view',
          failureCategory: category,
        );
      }
      ClinicalAccessAuditLogger.clinicalFullView(
        encounterId: trimmed,
        success: false,
        failureCategory: category,
      );
      return ClinicalEncounterDetailLoadResult.failure(
        ClinicalEncounterDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      ClinicalAccessAuditLogger.clinicalFullView(
        encounterId: trimmed,
        success: false,
        failureCategory: 'unknown',
      );
      return ClinicalEncounterDetailLoadResult.failure(
        ClinicalEncounterDetailUserMessages.genericLoadFailure,
      );
    }
  }
}
