import '../../../core/auth/auth_session.dart';
import '../../../core/auth/user_display_names.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/surgery_procedure_note.dart';

abstract final class SurgeryNoteOwnership {
  static String? currentProfileId() {
    final fromTenant = ActiveTenantContextStore.current?.profile.userId;
    if (fromTenant != null && fromTenant.trim().isNotEmpty) {
      return fromTenant.trim();
    }
    final fromSession = AuthSession.currentUser?.id;
    if (fromSession != null && fromSession.trim().isNotEmpty) {
      return fromSession.trim();
    }
    return null;
  }

  static String currentSurgeonDisplayName() {
    final fromTenant = ActiveTenantContextStore.current?.profile.displayName;
    if (fromTenant != null && fromTenant.trim().isNotEmpty) {
      return fromTenant.trim();
    }
    return AuthSession.currentUser?.displayName ??
        UserDisplayNames.mockDoctorLabel;
  }

  static bool canEditNote(SurgeryProcedureNote note) =>
      isVisibleToCurrentUser(note);

  static bool isVisibleToCurrentUser(SurgeryProcedureNote note) {
    final profileId = currentProfileId();
    final ownerId = note.createdByProfileId?.trim();
    if (profileId != null &&
        profileId.isNotEmpty &&
        ownerId != null &&
        ownerId.isNotEmpty) {
      return ownerId == profileId;
    }

    return note.surgeonName.trim().toLowerCase() ==
        currentSurgeonDisplayName().trim().toLowerCase();
  }
}
