/// Remote muayene repository hata nedenleri (UI'ya teknik detay sızdırılmaz).
enum ClinicalEncounterRepositoryFailure {
  forbidden,
  notFound,
  patientNotFound,
  appointmentNotFound,
  noActiveTenant,
  invalidClinicalData,
  network,
  notConfigured,
  unknown,
}

extension ClinicalEncounterRepositoryFailureMessage
    on ClinicalEncounterRepositoryFailure {
  String get message {
    switch (this) {
      case ClinicalEncounterRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case ClinicalEncounterRepositoryFailure.notFound:
        return 'Muayene kaydı bulunamadı.';
      case ClinicalEncounterRepositoryFailure.patientNotFound:
        return 'Seçilen hasta bulunamadı.';
      case ClinicalEncounterRepositoryFailure.appointmentNotFound:
        return 'Seçilen randevu bulunamadı.';
      case ClinicalEncounterRepositoryFailure.noActiveTenant:
        return 'Aktif klinik oturumu bulunamadı.';
      case ClinicalEncounterRepositoryFailure.invalidClinicalData:
        return 'Muayene verisi geçersiz.';
      case ClinicalEncounterRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case ClinicalEncounterRepositoryFailure.notConfigured:
        return 'Muayene altyapısı henüz aktif değil.';
      case ClinicalEncounterRepositoryFailure.unknown:
        return 'Muayene işlemi tamamlanamadı.';
    }
  }

  /// PostgREST / Postgres kod eşlemesi (ileride error mapper).
  ///
  /// `23503`: FK — caller bağlamına göre patient/appointment ayrımı.
  /// `42501`: RLS denied → [forbidden].
  static ClinicalEncounterRepositoryFailure? fromPostgresCode(String? code) {
    switch (code) {
      case '23503':
        return ClinicalEncounterRepositoryFailure.patientNotFound;
      case '23505':
        return ClinicalEncounterRepositoryFailure.invalidClinicalData;
      case '42501':
        return ClinicalEncounterRepositoryFailure.forbidden;
      default:
        return null;
    }
  }
}

class ClinicalEncounterRepositoryException implements Exception {
  final ClinicalEncounterRepositoryFailure reason;
  final Object? cause;

  const ClinicalEncounterRepositoryException(this.reason, {this.cause});

  @override
  String toString() => 'ClinicalEncounterRepositoryException($reason)';
}
