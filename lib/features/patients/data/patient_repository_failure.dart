/// Remote hasta repository hata nedenleri (UI'ya teknik detay sızdırılmaz).
enum PatientRepositoryFailure {
  duplicateFileNumber,
  forbidden,
  notFound,
  noActiveTenant,
  network,
  notConfigured,
  unknown,
}

extension PatientRepositoryFailureMessage on PatientRepositoryFailure {
  String get message {
    switch (this) {
      case PatientRepositoryFailure.duplicateFileNumber:
        return 'Bu dosya numarası zaten kullanılıyor.';
      case PatientRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case PatientRepositoryFailure.notFound:
        return 'Hasta bulunamadı.';
      case PatientRepositoryFailure.noActiveTenant:
        return 'Aktif klinik oturumu bulunamadı.';
      case PatientRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case PatientRepositoryFailure.notConfigured:
        return 'Hasta kayıt altyapısı henüz aktif değil.';
      case PatientRepositoryFailure.unknown:
        return 'Kayıt işlemi tamamlanamadı.';
    }
  }

  /// PostgREST `23505` unique violation → [duplicateFileNumber].
  static PatientRepositoryFailure? fromPostgresCode(String? code) {
    switch (code) {
      case '23505':
        return PatientRepositoryFailure.duplicateFileNumber;
      case '42501':
        return PatientRepositoryFailure.forbidden;
      default:
        return null;
    }
  }
}

/// Repository katmanı istisnası — ileride async implementasyonlar fırlatır.
class PatientRepositoryException implements Exception {
  final PatientRepositoryFailure reason;
  final Object? cause;

  const PatientRepositoryException(this.reason, {this.cause});

  @override
  String toString() => 'PatientRepositoryException($reason)';
}
