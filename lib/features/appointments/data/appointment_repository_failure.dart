/// Remote randevu repository hata nedenleri (UI'ya teknik detay sızdırılmaz).
enum AppointmentRepositoryFailure {
  forbidden,
  notFound,
  patientNotFound,
  noActiveTenant,
  invalidDateTime,
  network,
  notConfigured,
  unknown,
}

extension AppointmentRepositoryFailureMessage on AppointmentRepositoryFailure {
  String get message {
    switch (this) {
      case AppointmentRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case AppointmentRepositoryFailure.notFound:
        return 'Randevu bulunamadı.';
      case AppointmentRepositoryFailure.patientNotFound:
        return 'Seçilen hasta bulunamadı.';
      case AppointmentRepositoryFailure.noActiveTenant:
        return 'Aktif klinik oturumu bulunamadı.';
      case AppointmentRepositoryFailure.invalidDateTime:
        return 'Geçersiz tarih veya saat.';
      case AppointmentRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case AppointmentRepositoryFailure.notConfigured:
        return 'Randevu altyapısı henüz aktif değil.';
      case AppointmentRepositoryFailure.unknown:
        return 'Randevu işlemi tamamlanamadı.';
    }
  }

  /// PostgREST / Postgres kod eşlemesi (ileride error mapper).
  static AppointmentRepositoryFailure? fromPostgresCode(String? code) {
    switch (code) {
      case '23503':
        return AppointmentRepositoryFailure.patientNotFound;
      case '42501':
        return AppointmentRepositoryFailure.forbidden;
      default:
        return null;
    }
  }
}

class AppointmentRepositoryException implements Exception {
  final AppointmentRepositoryFailure reason;
  final Object? cause;

  const AppointmentRepositoryException(this.reason, {this.cause});

  @override
  String toString() => 'AppointmentRepositoryException($reason)';
}
