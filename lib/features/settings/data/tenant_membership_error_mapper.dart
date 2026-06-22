import 'package:supabase_flutter/supabase_flutter.dart';

import 'tenant_membership_failure.dart';

abstract final class TenantMembershipErrorMapper {
  static TenantMembershipFailure mapPostgrest(PostgrestException e) {
    final msg = (e.message).toLowerCase();
    if (msg.contains('self_update_blocked')) {
      return TenantMembershipFailure.selfUpdateBlocked;
    }
    if (msg.contains('last_admin_blocked')) {
      return TenantMembershipFailure.lastAdminBlocked;
    }
    if (msg.contains('invalid_role')) {
      return TenantMembershipFailure.invalidRole;
    }
    if (msg.contains('invalid_status')) {
      return TenantMembershipFailure.invalidStatus;
    }
    if (msg.contains('invitation_acceptance_required')) {
      return TenantMembershipFailure.invitationAcceptanceRequired;
    }
    if (msg.contains('not_found')) {
      return TenantMembershipFailure.notFound;
    }
    if (msg.contains('invalid_login_username')) {
      return TenantMembershipFailure.invalidLoginUsername;
    }
    if (msg.contains('login_username_taken')) {
      return TenantMembershipFailure.loginUsernameTaken;
    }
    if (msg.contains('no_active_tenant')) {
      return TenantMembershipFailure.noActiveTenant;
    }
    if (msg.contains('no_active_profile')) {
      return TenantMembershipFailure.noActiveProfile;
    }
    if (msg.contains('forbidden') || e.code == '42501' || e.code == 'PGRST301') {
      return TenantMembershipFailure.forbidden;
    }
    return TenantMembershipFailure.unknown;
  }

  static String messageFor(TenantMembershipFailure failure) {
    switch (failure) {
      case TenantMembershipFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case TenantMembershipFailure.notFound:
        return 'Kullanıcı kaydı bulunamadı.';
      case TenantMembershipFailure.invalidRole:
        return 'Geçersiz rol seçimi.';
      case TenantMembershipFailure.invalidStatus:
        return 'Geçersiz durum seçimi.';
      case TenantMembershipFailure.invitationAcceptanceRequired:
        return 'Davetli kullanıcı yalnızca daveti kabul ederek aktif olabilir.';
      case TenantMembershipFailure.lastAdminBlocked:
        return 'Son aktif doktor/admin pasif yapılamaz veya rolü düşürülemez.';
      case TenantMembershipFailure.selfUpdateBlocked:
        return 'Kendi rolünüzü bu ekrandan değiştiremezsiniz.';
      case TenantMembershipFailure.invalidLoginUsername:
        return 'Kullanıcı adı 3–32 karakter olmalı (a-z, 0-9, . _)';
      case TenantMembershipFailure.loginUsernameTaken:
        return 'Bu kullanıcı adı zaten kullanılıyor.';
      case TenantMembershipFailure.noActiveTenant:
      case TenantMembershipFailure.noActiveProfile:
        return 'Aktif klinik oturumu bulunamadı.';
      case TenantMembershipFailure.notConfigured:
        return 'Uzak veritabanı yapılandırılmadı.';
      case TenantMembershipFailure.unknown:
        return 'Kullanıcı bilgileri yüklenemedi. Lütfen tekrar deneyin.';
    }
  }
}
