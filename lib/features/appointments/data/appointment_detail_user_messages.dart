import 'appointment_repository_failure.dart';

/// Randevu detay — kullanıcıya gösterilen hata metinleri.
abstract final class AppointmentDetailUserMessages {
  static String forFailure(AppointmentRepositoryFailure reason) {
    switch (reason) {
      case AppointmentRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case AppointmentRepositoryFailure.forbidden:
        return 'Bu randevu kaydına erişim yetkiniz bulunmuyor.';
      case AppointmentRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case AppointmentRepositoryFailure.notConfigured:
        return 'Randevu detayı şu an kullanılamıyor.';
      case AppointmentRepositoryFailure.notFound:
        return 'Randevu bulunamadı.';
      case AppointmentRepositoryFailure.patientNotFound:
        return 'Seçilen hasta bulunamadı.';
      case AppointmentRepositoryFailure.invalidDateTime:
        return 'Geçersiz tarih veya saat.';
      case AppointmentRepositoryFailure.unknown:
        return genericLoadFailure;
      default:
        return genericLoadFailure;
    }
  }

  static const String loading = 'Randevu detayı yükleniyor…';
  static const String genericLoadFailure = 'Randevu detayı yüklenemedi.';
}
