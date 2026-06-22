/// Maintenance Bootstrap v2a — function/RPC hata eşlemesi (Türkçe UI mesajları).
library;

enum MaintenanceProvisionFailure {
  notAvailable,
  disabled,
  forbidden,
  invalidEmail,
  invalidRole,
  invalidStatus,
  invalidArguments,
  tenantNotFound,
  tenantInactive,
  authUserExists,
  profileConflict,
  membershipExists,
  bootstrapPartialFailure,
  authCreateFailed,
  databaseBootstrapFailed,
  rollbackFailed,
  alreadyExists,
  invalidResponse,
  unknown,
}

abstract final class MaintenanceProvisionErrorMapper {
  static MaintenanceProvisionFailure fromPostgrestMessage(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('maintenance_disabled')) {
      return MaintenanceProvisionFailure.disabled;
    }
    if (msg.contains('maintenance_forbidden')) {
      return MaintenanceProvisionFailure.forbidden;
    }
    if (msg.contains('empty_tenant_name') || msg.contains('invalid_email')) {
      return MaintenanceProvisionFailure.invalidEmail;
    }
    if (msg.contains('invalid_role')) {
      return MaintenanceProvisionFailure.invalidRole;
    }
    if (msg.contains('invalid_status') || msg.contains('invalid_tenant_status')) {
      return MaintenanceProvisionFailure.invalidStatus;
    }
    if (msg.contains('tenant_not_found')) {
      return MaintenanceProvisionFailure.tenantNotFound;
    }
    if (msg.contains('tenant_inactive')) {
      return MaintenanceProvisionFailure.tenantInactive;
    }
    if (msg.contains('profile_conflict') || msg.contains('auth_user_already_linked')) {
      return MaintenanceProvisionFailure.profileConflict;
    }
    if (msg.contains('membership_exists')) {
      return MaintenanceProvisionFailure.membershipExists;
    }
    return MaintenanceProvisionFailure.unknown;
  }

  static MaintenanceProvisionFailure fromFunctionError(String? code) {
    switch (code) {
      case 'maintenance_disabled':
        return MaintenanceProvisionFailure.disabled;
      case 'operator_required':
      case 'unauthorized':
        return MaintenanceProvisionFailure.forbidden;
      case 'invalid_email':
        return MaintenanceProvisionFailure.invalidEmail;
      case 'invalid_role':
        return MaintenanceProvisionFailure.invalidRole;
      case 'invalid_status':
        return MaintenanceProvisionFailure.invalidStatus;
      case 'invalid_arguments':
      case 'invalid_mode':
        return MaintenanceProvisionFailure.invalidArguments;
      case 'tenant_not_found':
        return MaintenanceProvisionFailure.tenantNotFound;
      case 'tenant_inactive':
        return MaintenanceProvisionFailure.tenantInactive;
      case 'auth_user_exists':
        return MaintenanceProvisionFailure.authUserExists;
      case 'profile_conflict':
        return MaintenanceProvisionFailure.profileConflict;
      case 'membership_exists':
        return MaintenanceProvisionFailure.membershipExists;
      case 'bootstrap_partial_failure':
        return MaintenanceProvisionFailure.bootstrapPartialFailure;
      case 'auth_create_failed':
        return MaintenanceProvisionFailure.authCreateFailed;
      case 'database_bootstrap_failed':
        return MaintenanceProvisionFailure.databaseBootstrapFailed;
      case 'rollback_failed':
        return MaintenanceProvisionFailure.rollbackFailed;
      case 'already_exists':
        return MaintenanceProvisionFailure.alreadyExists;
      default:
        return MaintenanceProvisionFailure.unknown;
    }
  }

  static String userMessage(MaintenanceProvisionFailure reason) {
    switch (reason) {
      case MaintenanceProvisionFailure.notAvailable:
        return 'Bakım provisioning bu ortamda kullanılamıyor.';
      case MaintenanceProvisionFailure.disabled:
        return 'Bakım provisioning sunucuda devre dışı.';
      case MaintenanceProvisionFailure.forbidden:
        return 'Bu işlem için bakım operatörü yetkisi gerekir.';
      case MaintenanceProvisionFailure.invalidEmail:
        return 'Geçerli bir e-posta adresi girin.';
      case MaintenanceProvisionFailure.invalidRole:
        return 'İlk yönetici rolü yalnızca Doktor olabilir.';
      case MaintenanceProvisionFailure.invalidStatus:
        return 'Geçersiz durum değeri.';
      case MaintenanceProvisionFailure.invalidArguments:
        return 'Form alanlarını kontrol edin.';
      case MaintenanceProvisionFailure.tenantNotFound:
        return 'Klinik bulunamadı.';
      case MaintenanceProvisionFailure.tenantInactive:
        return 'Klinik aktif değil; önce durumu kontrol edin.';
      case MaintenanceProvisionFailure.authUserExists:
        return 'Bu e-posta için Auth hesabı zaten var. Onarım v2c gerekli.';
      case MaintenanceProvisionFailure.profileConflict:
        return 'Profil/auth çakışması. Onarım v2c gerekli.';
      case MaintenanceProvisionFailure.membershipExists:
        return 'Üyelik çakışması. Mevcut üyeliği kontrol edin.';
      case MaintenanceProvisionFailure.bootstrapPartialFailure:
        return 'Kısmi bootstrap hatası. Teknik ekibe bildirin.';
      case MaintenanceProvisionFailure.authCreateFailed:
        return 'Auth hesabı oluşturulamadı.';
      case MaintenanceProvisionFailure.databaseBootstrapFailed:
        return 'Profil/üyelik zinciri tamamlanamadı.';
      case MaintenanceProvisionFailure.rollbackFailed:
        return 'Geri alma başarısız. Teknik müdahale gerekli.';
      case MaintenanceProvisionFailure.alreadyExists:
        return 'Bu kullanıcı zinciri zaten tamamlanmış.';
      case MaintenanceProvisionFailure.invalidResponse:
        return 'Sunucu yanıtı işlenemedi.';
      case MaintenanceProvisionFailure.unknown:
        return 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
    }
  }
}

class MaintenanceProvisionException implements Exception {
  final MaintenanceProvisionFailure reason;
  const MaintenanceProvisionException(this.reason);
}
