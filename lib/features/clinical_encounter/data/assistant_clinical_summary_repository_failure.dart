/// Assistant güvenli özet repository hata nedenleri.
enum AssistantClinicalSummaryRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  invalidRow,
  network,
  notConfigured,
  unknown,
}

extension AssistantClinicalSummaryRepositoryFailureMessage
    on AssistantClinicalSummaryRepositoryFailure {
  String get message {
    switch (this) {
      case AssistantClinicalSummaryRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case AssistantClinicalSummaryRepositoryFailure.notFound:
        return 'Klinik özet bulunamadı.';
      case AssistantClinicalSummaryRepositoryFailure.noActiveTenant:
        return 'Aktif klinik oturumu bulunamadı.';
      case AssistantClinicalSummaryRepositoryFailure.invalidRow:
        return 'Klinik özet verisi geçersiz.';
      case AssistantClinicalSummaryRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case AssistantClinicalSummaryRepositoryFailure.notConfigured:
        return 'Klinik özet altyapısı henüz aktif değil.';
      case AssistantClinicalSummaryRepositoryFailure.unknown:
        return 'Klinik özet işlemi tamamlanamadı.';
    }
  }
}

class AssistantClinicalSummaryRepositoryException implements Exception {
  final AssistantClinicalSummaryRepositoryFailure reason;
  final Object? cause;

  const AssistantClinicalSummaryRepositoryException(this.reason, {this.cause});

  @override
  String toString() => 'AssistantClinicalSummaryRepositoryException($reason)';
}
