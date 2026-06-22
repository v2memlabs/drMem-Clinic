import 'auth_failure_reason.dart';
import 'session_bootstrap.dart';

/// [SessionBootstrapResult] → kullanıcıya gösterilecek auth hata mesajı.
abstract final class AuthBootstrapMapper {
  static AuthFailureReason toFailureReason(SessionBootstrapStatus status) {
    switch (status) {
      case SessionBootstrapStatus.noMembership:
      case SessionBootstrapStatus.profileMissing:
        return AuthFailureReason.noMembership;
      case SessionBootstrapStatus.inactiveMembership:
        return AuthFailureReason.inactiveMembership;
      case SessionBootstrapStatus.inactiveTenant:
        return AuthFailureReason.inactiveTenant;
      case SessionBootstrapStatus.unknownRole:
        return AuthFailureReason.unknownRole;
      case SessionBootstrapStatus.needsTenantSelection:
        return AuthFailureReason.multipleMemberships;
      case SessionBootstrapStatus.backendNotConfigured:
        return AuthFailureReason.backendNotConfigured;
      case SessionBootstrapStatus.maintenanceAccessUnavailable:
        return AuthFailureReason.maintenanceAccessUnavailable;
      case SessionBootstrapStatus.maintenanceReady:
        return AuthFailureReason.membershipUnavailable;
      case SessionBootstrapStatus.invitationAcceptFailed:
        return AuthFailureReason.invitationAcceptFailed;
      case SessionBootstrapStatus.multiplePendingInvitations:
        return AuthFailureReason.multiplePendingInvitations;
      case SessionBootstrapStatus.ready:
      case SessionBootstrapStatus.notLoaded:
        return AuthFailureReason.membershipUnavailable;
    }
  }

  static String userMessage(SessionBootstrapStatus status) {
    switch (status) {
      case SessionBootstrapStatus.noMembership:
      case SessionBootstrapStatus.profileMissing:
        return 'Bu kullanıcı için aktif klinik üyeliği bulunamadı.';
      case SessionBootstrapStatus.inactiveMembership:
        return 'Klinik üyeliğiniz aktif değil.';
      case SessionBootstrapStatus.inactiveTenant:
        return 'Klinik hesabı aktif değil.';
      case SessionBootstrapStatus.unknownRole:
        return 'Rol bilgisi tanınamadı.';
      case SessionBootstrapStatus.needsTenantSelection:
        return 'Klinik seçimi sonraki sürümde aktif edilecektir.';
      case SessionBootstrapStatus.backendNotConfigured:
        return AuthFailureReason.backendNotConfigured.message;
      case SessionBootstrapStatus.maintenanceAccessUnavailable:
        return 'Bakım konsolu bu ortamda kullanılamıyor.';
      case SessionBootstrapStatus.maintenanceReady:
        return '';
      case SessionBootstrapStatus.invitationAcceptFailed:
        return AuthFailureReason.invitationAcceptFailed.message;
      case SessionBootstrapStatus.multiplePendingInvitations:
        return AuthFailureReason.multiplePendingInvitations.message;
      case SessionBootstrapStatus.ready:
        return '';
      case SessionBootstrapStatus.notLoaded:
        return 'Oturum hazırlanamadı.';
    }
  }
}
