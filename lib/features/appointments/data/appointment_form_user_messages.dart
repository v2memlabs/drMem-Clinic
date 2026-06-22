import 'appointment_repository_failure.dart';

/// Randevu form — kullanıcı mesajları.
abstract final class AppointmentFormUserMessages {
  static String forFailure(
    AppointmentRepositoryFailure reason, {
    required bool isEdit,
  }) {
    switch (reason) {
      case AppointmentRepositoryFailure.patientNotFound:
        return 'Seçilen hasta bulunamadı.';
      case AppointmentRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz bulunmuyor.';
      case AppointmentRepositoryFailure.noActiveTenant:
        return 'Oturum hazır değil. Lütfen tekrar giriş yapın.';
      case AppointmentRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case AppointmentRepositoryFailure.notConfigured:
        return 'Randevu kayıt altyapısı şu an kullanılamıyor.';
      case AppointmentRepositoryFailure.notFound:
        return 'Randevu bulunamadı.';
      case AppointmentRepositoryFailure.invalidDateTime:
        return 'Geçersiz tarih veya saat.';
      case AppointmentRepositoryFailure.unknown:
        return isEdit
            ? 'Randevu bilgileri güncellenemedi.'
            : 'Randevu oluşturulamadı.';
      default:
        return isEdit
            ? 'Randevu bilgileri güncellenemedi.'
            : 'Randevu oluşturulamadı.';
    }
  }

  static String successMessage({required bool isEdit}) {
    return isEdit ? 'Randevu güncellendi.' : 'Randevu kaydedildi.';
  }

  static const String loadFailure = 'Form yüklenemedi.';

  static const String physiotherapySchedulingNotice =
      'Fizik tedavi randevusu planlanıyor.';
}
