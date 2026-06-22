import 'patient_repository_failure.dart';

/// Hasta seçici — kullanıcıya gösterilen hata metinleri.
abstract final class PatientSelectorUserMessages {
  static String forFailure(PatientRepositoryFailure reason) {
    switch (reason) {
      case PatientRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case PatientRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case PatientRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case PatientRepositoryFailure.notConfigured:
        return 'Hasta listesi şu an kullanılamıyor.';
      default:
        return reason.message;
    }
  }

  static const String genericLoadFailure = 'Hasta listesi yüklenemedi.';
}
