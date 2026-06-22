/// Hasta etiket listesi — kullanıcı mesajları (teknik detay yok).
abstract final class PatientTagListUserMessages {
  static const String loading = 'Etiketler yükleniyor…';

  static const String notConfigured = 'Hasta etiketleri şu anda kullanılamıyor.';
  static const String notConfiguredDescription =
      'Etiket modülü henüz bu ortamda etkin değil. Oturum ve klinik bağlantısı '
      'hazır olduğunda burada listelenecek.';

  static const String errorTitle = 'Etiketler yüklenemedi';
  static const String genericError =
      'Etiketler yüklenirken bir sorun oluştu. Lütfen tekrar deneyin.';
}
