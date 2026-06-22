import '../auth/session_bootstrap.dart';

/// Hesap / membership erişim engeli nedeni.
enum AccountAccessReason {
  noMembership,
  inactiveMembership,
  inactiveTenant,
  unknownRole,
  needsTenantSelection,
  bootstrapFailed,
  maintenanceAccessUnavailable,
  invitationAcceptFailed,
  multiplePendingInvitations,
  generic,
}

extension AccountAccessReasonParsing on AccountAccessReason {
  static AccountAccessReason fromQuery(String? value) {
    switch (value) {
      case 'noMembership':
        return AccountAccessReason.noMembership;
      case 'inactiveMembership':
        return AccountAccessReason.inactiveMembership;
      case 'inactiveTenant':
        return AccountAccessReason.inactiveTenant;
      case 'unknownRole':
        return AccountAccessReason.unknownRole;
      case 'needsTenantSelection':
        return AccountAccessReason.needsTenantSelection;
      case 'bootstrapFailed':
        return AccountAccessReason.bootstrapFailed;
      case 'maintenanceAccessUnavailable':
        return AccountAccessReason.maintenanceAccessUnavailable;
      case 'invitationAcceptFailed':
        return AccountAccessReason.invitationAcceptFailed;
      case 'multiplePendingInvitations':
        return AccountAccessReason.multiplePendingInvitations;
      default:
        return AccountAccessReason.generic;
    }
  }

  static AccountAccessReason fromBootstrapStatus(SessionBootstrapStatus status) {
    switch (status) {
      case SessionBootstrapStatus.noMembership:
        return AccountAccessReason.noMembership;
      case SessionBootstrapStatus.inactiveMembership:
        return AccountAccessReason.inactiveMembership;
      case SessionBootstrapStatus.inactiveTenant:
        return AccountAccessReason.inactiveTenant;
      case SessionBootstrapStatus.unknownRole:
        return AccountAccessReason.unknownRole;
      case SessionBootstrapStatus.needsTenantSelection:
        return AccountAccessReason.needsTenantSelection;
      case SessionBootstrapStatus.backendNotConfigured:
      case SessionBootstrapStatus.profileMissing:
      case SessionBootstrapStatus.notLoaded:
        return AccountAccessReason.bootstrapFailed;
      case SessionBootstrapStatus.maintenanceAccessUnavailable:
        return AccountAccessReason.maintenanceAccessUnavailable;
      case SessionBootstrapStatus.invitationAcceptFailed:
        return AccountAccessReason.invitationAcceptFailed;
      case SessionBootstrapStatus.multiplePendingInvitations:
        return AccountAccessReason.multiplePendingInvitations;
      case SessionBootstrapStatus.maintenanceReady:
      case SessionBootstrapStatus.ready:
        return AccountAccessReason.generic;
    }
  }

  String get title {
    switch (this) {
      case AccountAccessReason.noMembership:
        return 'Klinik erişiminiz bulunmuyor';
      case AccountAccessReason.inactiveMembership:
        return 'Üyeliğiniz pasif durumda';
      case AccountAccessReason.inactiveTenant:
        return 'Klinik hesabı askıda';
      case AccountAccessReason.unknownRole:
        return 'Rol tanımlanamadı';
      case AccountAccessReason.needsTenantSelection:
        return 'Klinik seçimi gerekli';
      case AccountAccessReason.bootstrapFailed:
        return 'Oturum hazırlanamadı';
      case AccountAccessReason.maintenanceAccessUnavailable:
        return 'Bakım konsolu bu ortamda kullanılamıyor';
      case AccountAccessReason.invitationAcceptFailed:
        return 'Davet kabul edilemedi';
      case AccountAccessReason.multiplePendingInvitations:
        return 'Birden fazla bekleyen davet';
      case AccountAccessReason.generic:
        return 'Hesap erişimi kullanılamıyor';
    }
  }

  String get description {
    switch (this) {
      case AccountAccessReason.noMembership:
        return 'Bu hesap için tanımlı bir klinik üyeliği yok. Yöneticinizle iletişime geçin.';
      case AccountAccessReason.inactiveMembership:
        return 'Klinik üyeliğiniz şu an aktif değil.';
      case AccountAccessReason.inactiveTenant:
        return 'Bağlı olduğunuz klinik hesabı geçici olarak askıya alınmış.';
      case AccountAccessReason.unknownRole:
        return 'Kullanıcı rolünüz sistemde tanınmıyor. Destek ekibiyle iletişime geçin.';
      case AccountAccessReason.needsTenantSelection:
        return 'Birden fazla klinik erişiminiz var. Klinik seçimi sonraki sürümde eklenecek.';
      case AccountAccessReason.bootstrapFailed:
        return 'Giriş bilgileriniz alındı ancak oturum tamamlanamadı. Lütfen tekrar deneyin.';
      case AccountAccessReason.maintenanceAccessUnavailable:
        return 'Bakım operatörü hesabı yalnızca staging/dev bakım modunda açılabilir. Klinik uygulamasına yönlendirilmezsiniz.';
      case AccountAccessReason.invitationAcceptFailed:
        return 'Davetiniz kabul edilemedi. Lütfen yöneticinizle iletişime geçin veya daveti yeniden göndermesini isteyin.';
      case AccountAccessReason.multiplePendingInvitations:
        return 'Birden fazla bekleyen klinik davetiniz var. Yöneticinizle iletişime geçin.';
      case AccountAccessReason.generic:
        return 'Hesabınızla klinik uygulamasına erişilemiyor.';
    }
  }

  String get queryValue {
    switch (this) {
      case AccountAccessReason.noMembership:
        return 'noMembership';
      case AccountAccessReason.inactiveMembership:
        return 'inactiveMembership';
      case AccountAccessReason.inactiveTenant:
        return 'inactiveTenant';
      case AccountAccessReason.unknownRole:
        return 'unknownRole';
      case AccountAccessReason.needsTenantSelection:
        return 'needsTenantSelection';
      case AccountAccessReason.bootstrapFailed:
        return 'bootstrapFailed';
      case AccountAccessReason.maintenanceAccessUnavailable:
        return 'maintenanceAccessUnavailable';
      case AccountAccessReason.invitationAcceptFailed:
        return 'invitationAcceptFailed';
      case AccountAccessReason.multiplePendingInvitations:
        return 'multiplePendingInvitations';
      case AccountAccessReason.generic:
        return 'generic';
    }
  }
}
