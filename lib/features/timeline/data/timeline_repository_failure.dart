/// Timeline repository hata nedenleri.
enum TimelineRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  invalidInput,
  invalidRow,
  network,
  unknown,
}

extension TimelineRepositoryFailureMessage on TimelineRepositoryFailure {
  String get message {
    switch (this) {
      case TimelineRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case TimelineRepositoryFailure.notFound:
        return 'Timeline kaydı bulunamadı.';
      case TimelineRepositoryFailure.noActiveTenant:
        return 'Aktif klinik oturumu bulunamadı.';
      case TimelineRepositoryFailure.notConfigured:
        return 'Timeline altyapısı henüz aktif değil.';
      case TimelineRepositoryFailure.invalidInput:
        return 'Timeline girişi geçersiz.';
      case TimelineRepositoryFailure.invalidRow:
        return 'Timeline verisi geçersiz.';
      case TimelineRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case TimelineRepositoryFailure.unknown:
        return 'Timeline işlemi tamamlanamadı.';
    }
  }
}

class TimelineRepositoryException implements Exception {
  final TimelineRepositoryFailure reason;
  final Object? cause;

  const TimelineRepositoryException(this.reason, {this.cause});

  @override
  String toString() => 'TimelineRepositoryException($reason)';
}
