import 'clinical_encounter_repository_failure.dart';

/// Muayene listesi — kullanıcıya gösterilen hata metinleri.
abstract final class ClinicalEncounterListUserMessages {
  static const String loading = 'Muayene kayıtları yükleniyor...';
  static const String emptyForPatient = 'Bu hasta için kayıtlı muayene bulunamadı.';
  static const String emptyGeneric = 'Kayıtlı muayene bulunamadı.';

  static String forFailure(ClinicalEncounterRepositoryFailure reason) {
    switch (reason) {
      case ClinicalEncounterRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case ClinicalEncounterRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case ClinicalEncounterRepositoryFailure.network:
        return 'Muayene kayıtları yüklenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
      case ClinicalEncounterRepositoryFailure.notConfigured:
        return 'Muayene kayıtları şu an kullanılamıyor.';
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
      'Muayene kayıtları yüklenemedi. Lütfen tekrar deneyin.';
}
