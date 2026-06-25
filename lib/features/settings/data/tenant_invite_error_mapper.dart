import 'package:supabase_flutter/supabase_flutter.dart';

import 'tenant_invite_failure.dart';

abstract final class TenantInviteErrorMapper {
  static TenantInviteFailure fromFunctionError(String? code) {
    switch (code) {
      case 'unauthorized':
      case 'doctor_admin_required':
        return TenantInviteFailure.forbidden;
      case 'no_active_tenant':
        return TenantInviteFailure.noActiveTenant;
      case 'tenant_inactive':
        return TenantInviteFailure.tenantInactive;
      case 'invalid_email':
        return TenantInviteFailure.invalidEmail;
      case 'invalid_display_name':
        return TenantInviteFailure.invalidDisplayName;
      case 'invalid_role':
        return TenantInviteFailure.invalidRole;
      case 'invalid_login_username':
        return TenantInviteFailure.invalidLoginUsername;
      case 'invalid_password':
        return TenantInviteFailure.invalidPassword;
      case 'login_username_taken':
        return TenantInviteFailure.loginUsernameTaken;
      case 'auth_invite_failed':
        return TenantInviteFailure.authInviteFailed;
      case 'auth_user_exists':
        return TenantInviteFailure.authUserExists;
      case 'self_invite_blocked':
        return TenantInviteFailure.selfInviteBlocked;
      case 'profile_conflict':
        return TenantInviteFailure.profileConflict;
      case 'auth_user_already_linked':
        return TenantInviteFailure.authUserAlreadyLinked;
      case 'membership_already_active':
        return TenantInviteFailure.membershipAlreadyActive;
      case 'invitation_already_pending':
        return TenantInviteFailure.invitationAlreadyPending;
      case 'invitation_not_found':
        return TenantInviteFailure.invitationNotFound;
      case 'invitation_not_pending':
        return TenantInviteFailure.invitationNotPending;
      case 'invite_rate_limited':
        return TenantInviteFailure.inviteRateLimited;
      case 'auth_email_rate_limited':
        return TenantInviteFailure.authEmailRateLimited;
      case 'database_bootstrap_failed':
        return TenantInviteFailure.databaseBootstrapFailed;
      case 'rollback_failed':
        return TenantInviteFailure.rollbackFailed;
      default:
        return TenantInviteFailure.unknown;
    }
  }

  static TenantInviteFailure fromPostgrest(PostgrestException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invitation_not_found') || msg.contains('not_found')) {
      return TenantInviteFailure.invitationNotFound;
    }
    if (msg.contains('invitation_not_pending')) {
      return TenantInviteFailure.invitationNotPending;
    }
    if (msg.contains('invite_rate_limited')) {
      return TenantInviteFailure.inviteRateLimited;
    }
    if (msg.contains('multiple_pending_invitations')) {
      return TenantInviteFailure.multiplePendingInvitations;
    }
    if (msg.contains('forbidden') ||
        msg.contains('no_active_profile') ||
        e.code == '42501' ||
        e.code == 'PGRST301') {
      return TenantInviteFailure.forbidden;
    }
    if (msg.contains('tenant_inactive')) {
      return TenantInviteFailure.tenantInactive;
    }
    return TenantInviteFailure.unknown;
  }

  static TenantInviteFailure fromPostgrestForAccept(PostgrestException e) {
    final failure = fromPostgrest(e);
    if (failure == TenantInviteFailure.unknown) {
      return TenantInviteFailure.invitationAcceptFailed;
    }
    return failure;
  }

  static String messageFor(TenantInviteFailure failure) {
    switch (failure) {
      case TenantInviteFailure.notConfigured:
        return 'Davet altyapısı yapılandırılmadı.';
      case TenantInviteFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case TenantInviteFailure.noActiveTenant:
        return 'Aktif klinik seçimi bulunamadı.';
      case TenantInviteFailure.tenantInactive:
        return 'Klinik hesabı şu an davet göndermeye uygun değil.';
      case TenantInviteFailure.invalidEmail:
        return 'Geçerli bir e-posta adresi girin.';
      case TenantInviteFailure.invalidDisplayName:
        return 'Görünen ad zorunludur.';
      case TenantInviteFailure.invalidRole:
        return 'Geçersiz rol seçimi.';
      case TenantInviteFailure.invalidLoginUsername:
        return 'Giriş kullanıcı adı 3–32 karakter olmalı (a-z, 0-9, . _)';
      case TenantInviteFailure.invalidPassword:
        return 'Başlangıç şifresi en az 8 karakter olmalıdır.';
      case TenantInviteFailure.loginUsernameTaken:
        return 'Bu kullanıcı adı zaten kullanılıyor.';
      case TenantInviteFailure.authInviteFailed:
        return 'Davet e-postası gönderilemedi. Lütfen tekrar deneyin.';
      case TenantInviteFailure.authUserExists:
        return 'Bu e-posta adresi zaten bir hesap olarak kayıtlı. '
            'DL smoke için yeni bir test adresi deneyin (ör. deeplink-smoke-20260607@example.test).';
      case TenantInviteFailure.selfInviteBlocked:
        return 'Kendi e-posta adresinize davet gönderemezsiniz. Farklı bir adres girin.';
      case TenantInviteFailure.profileConflict:
        return 'Kullanıcı profili eşleştirilemiyor. Destek ile iletişime geçin.';
      case TenantInviteFailure.authUserAlreadyLinked:
        return 'Hesap başka bir profile bağlı.';
      case TenantInviteFailure.membershipAlreadyActive:
        return 'Bu kullanıcı zaten klinikte aktif.';
      case TenantInviteFailure.invitationAlreadyPending:
        return 'Bekleyen davet zaten var.';
      case TenantInviteFailure.invitationNotFound:
        return 'Davet kaydı bulunamadı.';
      case TenantInviteFailure.invitationNotPending:
        return 'Bu davet artık beklemede değil.';
      case TenantInviteFailure.multiplePendingInvitations:
        return 'Birden fazla bekleyen davet var. Yöneticinizle iletişime geçin.';
      case TenantInviteFailure.invitationAcceptFailed:
        return 'Davet kabul edilemedi. Lütfen yöneticinizle iletişime geçin.';
      case TenantInviteFailure.inviteRateLimited:
        return 'Davet kısa süre önce gönderildi. Lütfen biraz sonra tekrar deneyin.';
      case TenantInviteFailure.authEmailRateLimited:
        return 'E-posta gönderim limiti aşıldı. Staging Supabase saatlik mail '
            'kotasına takılmış olabilirsiniz — 30–60 dakika bekleyin, '
            'sonra yeni bir adres deneyin (ör. ad+dl20260607@gmail.com).';
      case TenantInviteFailure.databaseBootstrapFailed:
        return 'Davet kaydedilemedi. Lütfen tekrar deneyin.';
      case TenantInviteFailure.rollbackFailed:
        return 'Davet tamamlanamadı. Yöneticinize bildirin.';
      case TenantInviteFailure.invalidResponse:
        return 'Sunucu yanıtı işlenemedi.';
      case TenantInviteFailure.unknown:
        return 'İşlem tamamlanamadı. Lütfen tekrar deneyin.';
    }
  }
}
