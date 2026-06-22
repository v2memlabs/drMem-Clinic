import 'clinical_encounter_repository_failure.dart';

/// Muayene detay — kullanıcıya gösterilen hata metinleri.
abstract final class ClinicalEncounterDetailUserMessages {
  static const String loading = 'Muayene detayı yükleniyor...';
  static const String notFound = 'Muayene kaydı bulunamadı.';

  static String forFailure(ClinicalEncounterRepositoryFailure reason) {
    switch (reason) {
      case ClinicalEncounterRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case ClinicalEncounterRepositoryFailure.forbidden:
        return 'Bu muayene kaydına erişim yetkiniz bulunmuyor.';
      case ClinicalEncounterRepositoryFailure.network:
        return 'Muayene detayı yüklenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
      case ClinicalEncounterRepositoryFailure.notConfigured:
        return 'Muayene detayı şu an kullanılamıyor.';
      case ClinicalEncounterRepositoryFailure.notFound:
        return 'Muayene kaydı bulunamadı.';
      case ClinicalEncounterRepositoryFailure.invalidClinicalData:
        return 'Muayene verisi okunamadı.';
      case ClinicalEncounterRepositoryFailure.unknown:
        return genericLoadFailure;
      default:
        return genericLoadFailure;
    }
  }

  static const String genericLoadFailure =
      'Muayene detayı yüklenemedi. Lütfen tekrar deneyin.';
}
