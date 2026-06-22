import 'clinical_encounter_repository_failure.dart';

/// Muayene form — kullanıcı mesajları.
abstract final class ClinicalEncounterFormUserMessages {
  static String savingMessage({required bool isEdit}) {
    return isEdit
        ? 'Muayene kaydı güncelleniyor...'
        : 'Muayene kaydı oluşturuluyor...';
  }

  static String forFailure(
    ClinicalEncounterRepositoryFailure reason, {
    required bool isEdit,
  }) {
    switch (reason) {
      case ClinicalEncounterRepositoryFailure.patientNotFound:
        return 'Seçilen hasta bulunamadı.';
      case ClinicalEncounterRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz bulunmuyor. Oturumu kapatıp tekrar giriş yapmayı deneyin.';
      case ClinicalEncounterRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case ClinicalEncounterRepositoryFailure.network:
        return isEdit
            ? 'Muayene kaydı güncellenemedi. Lütfen tekrar deneyin.'
            : 'Muayene kaydı oluşturulamadı. Lütfen bilgileri kontrol edip tekrar deneyin.';
      case ClinicalEncounterRepositoryFailure.notConfigured:
        return 'Muayene kayıt altyapısı şu an kullanılamıyor.';
      case ClinicalEncounterRepositoryFailure.notFound:
        return 'Muayene kaydı bulunamadı.';
      case ClinicalEncounterRepositoryFailure.invalidClinicalData:
        return 'Muayene verisi geçersiz.';
      case ClinicalEncounterRepositoryFailure.unknown:
        return isEdit
            ? 'Muayene kaydı güncellenemedi.'
            : 'Muayene kaydı oluşturulamadı.';
      default:
        return isEdit
            ? 'Muayene kaydı güncellenemedi.'
            : 'Muayene kaydı oluşturulamadı.';
    }
  }

  static String successMessage({required bool isEdit, required bool usesRemote}) {
    if (isEdit) return 'Muayene kaydı güncellendi.';
    return usesRemote
        ? 'Muayene kaydı kaydedildi.'
        : 'Muayene kaydı kaydedildi (mock).';
  }

  static const String loadFailure = 'Form yüklenemedi.';
}
