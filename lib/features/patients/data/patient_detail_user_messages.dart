import 'patient_repository_failure.dart';

/// Hasta detay — kullanıcıya gösterilen hata metinleri.
abstract final class PatientDetailUserMessages {
  static String forFailure(PatientRepositoryFailure reason) {
    switch (reason) {
      case PatientRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case PatientRepositoryFailure.forbidden:
        return 'Bu hasta kaydına erişim yetkiniz bulunmuyor.';
      case PatientRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case PatientRepositoryFailure.notConfigured:
        return 'Hasta detayı şu an kullanılamıyor.';
      case PatientRepositoryFailure.notFound:
        return 'Hasta bulunamadı.';
      default:
        return reason.message;
    }
  }

  static const String genericLoadFailure = 'Hasta detayı yüklenemedi.';
}
