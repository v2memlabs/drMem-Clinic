import '../../../core/auth/auth_session.dart';
import '../../../core/session/record_ownership_context.dart';
import '../models/clinical_encounter.dart';

abstract final class ClinicalEncounterOwnership {
  static bool isVisibleToCurrentUser(ClinicalEncounter encounter) {
    if (!AuthSession.canViewFullClinicalEncounter) return false;

    final profileId = RecordOwnershipContext.currentProfileId();
    final ownerId = encounter.createdByProfileId?.trim();
    if (profileId != null &&
        profileId.isNotEmpty &&
        ownerId != null &&
        ownerId.isNotEmpty) {
      return ownerId == profileId;
    }

    return encounter.doctorName.trim().toLowerCase() ==
        RecordOwnershipContext.currentDisplayName().toLowerCase();
  }
}
