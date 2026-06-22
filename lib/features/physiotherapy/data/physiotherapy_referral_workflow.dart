import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/physiotherapy_referral.dart';

/// Doktor → fizyoterapist yönlendirme iş akışı durumları.
abstract final class PhysiotherapyReferralWorkflow {
  static bool isAssignedToCurrentUser(PhysiotherapyReferral referral) {
    if (!AuthSession.isPhysiotherapist) return true;
    final assignedId = referral.assignedPhysiotherapistProfileId?.trim();
    if (assignedId == null || assignedId.isEmpty) return true;
    final currentId = ActiveTenantContextStore.current?.userId?.trim() ??
        AuthSession.currentUser?.id.trim();
    if (currentId == null || currentId.isEmpty) return false;
    return assignedId == currentId;
  }

  static bool canPhysioBookAppointment(PhysiotherapyReferral referral) {
    if (!AuthSession.canBookReferralAppointments) return false;
    if (!AuthSession.isPhysiotherapist) {
      return AuthSession.canEditAppointments;
    }
    return isAssignedToCurrentUser(referral) && referral.isPendingPhysioAction;
  }

  static bool canCreateRehabPlan(PhysiotherapyReferral referral) {
    if (!AuthSession.canEditExercisePlans) return false;
    if (AuthSession.isPhysiotherapist && !isAssignedToCurrentUser(referral)) {
      return false;
    }
    return referral.hasScheduledAppointment;
  }

  static bool canViewPatientFile(PhysiotherapyReferral referral) {
    if (!AuthSession.isPhysiotherapist) return true;
    if (!isAssignedToCurrentUser(referral)) return false;
    return referral.hasScheduledAppointment;
  }

  static bool canCreateSession(PhysiotherapyReferral referral) {
    if (!AuthSession.canEditPhysiotherapy) return false;
    if (AuthSession.isPhysiotherapist && !isAssignedToCurrentUser(referral)) {
      return false;
    }
    return referral.hasScheduledAppointment;
  }
}
