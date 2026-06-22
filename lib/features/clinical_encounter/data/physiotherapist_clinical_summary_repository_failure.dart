/// Physiotherapist güvenli özet repository hata nedenleri.
enum PhysiotherapistClinicalSummaryRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  invalidRow,
  network,
  notConfigured,
  unknown,
}

extension PhysiotherapistClinicalSummaryRepositoryFailureMessage
    on PhysiotherapistClinicalSummaryRepositoryFailure {
  String get message {
    switch (this) {
      case PhysiotherapistClinicalSummaryRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.notFound:
        return 'Klinik özet bulunamadı.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.noActiveTenant:
        return 'Aktif klinik oturumu bulunamadı.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.invalidRow:
        return 'Klinik özet verisi geçersiz.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.notConfigured:
        return 'FTR klinik özet altyapısı henüz aktif değil.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.unknown:
        return 'Klinik özet işlemi tamamlanamadı.';
    }
  }
}

class PhysiotherapistClinicalSummaryRepositoryException implements Exception {
  final PhysiotherapistClinicalSummaryRepositoryFailure reason;
  final Object? cause;

  const PhysiotherapistClinicalSummaryRepositoryException(this.reason,
      {this.cause});

  @override
  String toString() =>
      'PhysiotherapistClinicalSummaryRepositoryException($reason)';
}
