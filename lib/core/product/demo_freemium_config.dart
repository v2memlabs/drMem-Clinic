/// Demo / freemium ürün sabitleri (UI bilgilendirme; enforcement yok).
abstract final class DemoFreemiumConfig {
  static const String productModeLabel = 'Demo';

  /// Ücretsiz demo kullanımda gösterilen hasta kayıt limiti (bilgilendirme).
  static const int demoPatientRecordLimit = 3;

  static const String patientLimitNote =
      'Limit yalnızca bilgilendirme içindir; hasta kayıt akışı bu sürümde engellenmez.';

  static const List<String> futureMeteredServices = [
    'SMS / WhatsApp bildirimleri',
    'PDF paylaşımı ve depolama',
    'AI destekli klinik özet',
    'Gelişmiş raporlar',
    'Ek depolama alanı',
  ];
}
