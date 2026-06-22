import 'patient_file_metadata_repository_failure.dart';

/// Hasta dosya metadata listesi — kullanıcı mesajları.
abstract final class PatientFileMetadataListUserMessages {
  static const String loading = 'Dosya kayıtları yükleniyor…';
  static const String emptyForPatient =
      'Bu hasta için kayıtlı dosya veya PDF çıktısı bulunamadı.';
  static const String emptyForTenant =
      'Kayıtlı dosya veya PDF çıktısı bulunamadı.';
  static const String notConfigured =
      'Dosya kayıtları şu anda görüntülenemiyor.';
  static const String notConfiguredDescription =
      'Bu alan henüz etkin değil.';
  static const String errorTitle = 'Dosya kayıtları yüklenemedi';
  static const String errorDescription =
      'Dosya kayıtları yüklenemedi. Lütfen tekrar deneyin.';
  static const String previewUnavailable =
      'Önizleme ve indirme sonraki sürümde etkinleşecek.';

  static String forFailure(PatientFileMetadataRepositoryFailure reason) {
    switch (reason) {
      case PatientFileMetadataRepositoryFailure.notConfigured:
        return notConfigured;
      case PatientFileMetadataRepositoryFailure.noActiveTenant:
        return 'Dosya kayıtları için aktif klinik oturumu gerekli.';
      case PatientFileMetadataRepositoryFailure.forbidden:
        return 'Bu dosya kayıtlarını görüntüleme yetkiniz bulunmuyor.';
      case PatientFileMetadataRepositoryFailure.network:
        return errorDescription;
      case PatientFileMetadataRepositoryFailure.notFound:
        return emptyForPatient;
      case PatientFileMetadataRepositoryFailure.invalidRow:
      case PatientFileMetadataRepositoryFailure.invalidInput:
      case PatientFileMetadataRepositoryFailure.unknown:
        return errorDescription;
    }
  }
}
