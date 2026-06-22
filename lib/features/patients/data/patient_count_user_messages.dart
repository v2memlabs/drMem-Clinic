import 'patient_repository_failure.dart';

/// Ayarlar demo kartı — hasta sayısı hata mesajları.
abstract final class PatientCountUserMessages {
  static String forFailure(PatientRepositoryFailure reason) {
    switch (reason) {
      case PatientRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case PatientRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case PatientRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case PatientRepositoryFailure.notConfigured:
        return 'Hasta sayısı şu an alınamıyor.';
      default:
        return reason.message;
    }
  }

  static const String genericFailure = 'Hasta sayısı alınamadı.';
}
