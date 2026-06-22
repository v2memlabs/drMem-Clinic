/// Auth işlemi başarısızlık nedenleri (mock + Supabase yolları).
enum AuthFailureReason {
  /// Boş veya geçersiz kimlik bilgileri.
  invalidCredentials,

  /// Mock demo girişi bu repository'de desteklenmiyor (Supabase stub).
  mockSignInNotSupported,

  /// E-posta/şifre girişi mock adapter'da kullanılmıyor.
  emailSignInNotSupported,

  /// Supabase yapılandırması veya gerçek implementasyon henüz yok.
  backendNotConfigured,

  /// Bilinmeyen veya eşlenemeyen rol.
  unknownRole,

  /// Üyelik / tenant bağlamı yüklenemedi.
  membershipUnavailable,

  /// Aktif klinik üyeliği yok.
  noMembership,

  /// Üyelik pasif.
  inactiveMembership,

  /// Tenant pasif / askıda.
  inactiveTenant,

  /// Birden fazla membership — tenant picker sonraki faz.
  multipleMemberships,

  /// Bakım operatörü — bakım modu bu ortamda kapalı.
  maintenanceAccessUnavailable,

  /// Davet kabul edilemedi.
  invitationAcceptFailed,

  /// Birden fazla bekleyen davet.
  multiplePendingInvitations,
}

extension AuthFailureReasonMessage on AuthFailureReason {
  String get message {
    switch (this) {
      case AuthFailureReason.invalidCredentials:
        return 'Giriş başarısız. Kullanıcı adı veya şifre hatalı.';
      case AuthFailureReason.mockSignInNotSupported:
        return 'Demo giriş bu modda kullanılamaz.';
      case AuthFailureReason.emailSignInNotSupported:
        return 'E-posta ile giriş bu modda kullanılamaz.';
      case AuthFailureReason.backendNotConfigured:
        return 'Gerçek giriş altyapısı henüz aktif değil.';
      case AuthFailureReason.unknownRole:
        return 'Rol bilgisi tanınamadı.';
      case AuthFailureReason.membershipUnavailable:
        return 'Klinik erişimi bulunamadı.';
      case AuthFailureReason.noMembership:
        return 'Bu kullanıcı için aktif klinik üyeliği bulunamadı.';
      case AuthFailureReason.inactiveMembership:
        return 'Klinik üyeliğiniz aktif değil.';
      case AuthFailureReason.inactiveTenant:
        return 'Klinik hesabı aktif değil.';
      case AuthFailureReason.multipleMemberships:
        return 'Klinik seçimi sonraki sürümde aktif edilecektir.';
      case AuthFailureReason.maintenanceAccessUnavailable:
        return 'Bakım konsolu bu ortamda kullanılamıyor.';
      case AuthFailureReason.invitationAcceptFailed:
        return 'Davet kabul edilemedi. Lütfen yöneticinizle iletişime geçin.';
      case AuthFailureReason.multiplePendingInvitations:
        return 'Birden fazla bekleyen davet var. Yöneticinizle iletişime geçin.';
    }
  }

  /// Supabase login ekranı — teknik detay göstermeden kısa mesajlar.
  static String forSupabaseLogin(AuthFailureReason reason) {
    switch (reason) {
      case AuthFailureReason.invalidCredentials:
        return invalidCredentialsUserMessage;
      case AuthFailureReason.backendNotConfigured:
        return 'Giriş altyapısı yapılandırılmadı.';
      default:
        return reason.message;
    }
  }

  /// Supabase Auth API hataları için genel mesaj.
  static String get invalidCredentialsUserMessage =>
      'Giriş bilgileri doğrulanamadı.';
}
