/// Patient file metadata repository hata nedenleri.
enum PatientFileMetadataRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  invalidInput,
  invalidRow,
  network,
  unknown,
}

extension PatientFileMetadataRepositoryFailureMessage
    on PatientFileMetadataRepositoryFailure {
  String get message {
    switch (this) {
      case PatientFileMetadataRepositoryFailure.forbidden:
        return 'Bu işlem için yetkiniz yok.';
      case PatientFileMetadataRepositoryFailure.notFound:
        return 'Dosya kaydı bulunamadı.';
      case PatientFileMetadataRepositoryFailure.noActiveTenant:
        return 'Aktif klinik oturumu bulunamadı.';
      case PatientFileMetadataRepositoryFailure.notConfigured:
        return 'Dosya metadata altyapısı henüz aktif değil.';
      case PatientFileMetadataRepositoryFailure.invalidInput:
        return 'Dosya metadata girişi geçersiz.';
      case PatientFileMetadataRepositoryFailure.invalidRow:
        return 'Dosya metadata verisi geçersiz.';
      case PatientFileMetadataRepositoryFailure.network:
        return 'Bağlantı kurulamadı. Lütfen tekrar deneyin.';
      case PatientFileMetadataRepositoryFailure.unknown:
        return 'Dosya metadata işlemi tamamlanamadı.';
    }
  }
}

class PatientFileMetadataRepositoryException implements Exception {
  final PatientFileMetadataRepositoryFailure reason;
  final Object? cause;

  const PatientFileMetadataRepositoryException(this.reason, {this.cause});

  @override
  String toString() => 'PatientFileMetadataRepositoryException($reason)';
}
