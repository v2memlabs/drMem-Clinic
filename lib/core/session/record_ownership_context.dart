import '../auth/auth_session.dart';
import '../auth/user_display_names.dart';
import '../constants/app_roles.dart';
import 'active_tenant_context_store.dart';

abstract final class RecordOwnershipContext {
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

  static String currentDisplayName() {
    final fromTenant = ActiveTenantContextStore.current?.profile.displayName;
    if (fromTenant != null && fromTenant.trim().isNotEmpty) {
      return fromTenant.trim();
    }
    return AuthSession.currentUser?.displayName ??
        UserDisplayNames.mockDoctorLabel;
  }

  static bool get isDoctor =>
      AuthSession.currentUser?.role == AppRoles.doctor;

  static bool get isPhysiotherapist =>
      AuthSession.currentUser?.role == AppRoles.physiotherapist;

  static bool get seesAllAppointments =>
      AuthSession.currentUser?.role == AppRoles.assistant ||
      AuthSession.currentUser?.role == AppRoles.nurse;
}
