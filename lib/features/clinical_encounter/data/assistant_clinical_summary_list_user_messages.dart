import 'assistant_clinical_summary_repository_failure.dart';

/// Assistant klinik özet listesi — kullanıcı mesajları.
abstract final class AssistantClinicalSummaryListUserMessages {
  static const String loading = 'Klinik özetler yükleniyor…';
  static const String emptyGeneric =
      'Görüntülenebilecek klinik özet bulunamadı.';
  static const String emptyForPatient =
      'Bu hasta için görüntülenebilecek klinik özet bulunamadı.';
  static const String errorTitle = 'Klinik özetler yüklenemedi';

  static const String notConfigured =
      'Klinik özetler şu anda görüntülenemiyor.';
  static const String notConfiguredDescription =
      'Güvenli klinik özet modülü henüz bu ortamda etkin değil. '
      'Oturum hazır olduğunda burada listelenecek.';

  static String forFailure(AssistantClinicalSummaryRepositoryFailure reason) {
    switch (reason) {
      case AssistantClinicalSummaryRepositoryFailure.noActiveTenant:
        return 'Klinik özetlere erişmek için aktif klinik oturumu gerekli.';
      case AssistantClinicalSummaryRepositoryFailure.forbidden:
        return 'Bu klinik özeti görüntüleme yetkiniz bulunmuyor.';
      case AssistantClinicalSummaryRepositoryFailure.network:
        return 'Klinik özetler yüklenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
      case AssistantClinicalSummaryRepositoryFailure.notConfigured:
        return 'Klinik özetler şu anda görüntülenemiyor.';
      case AssistantClinicalSummaryRepositoryFailure.notFound:
        return emptyGeneric;
      case AssistantClinicalSummaryRepositoryFailure.invalidRow:
        return malformedResponse;
      case AssistantClinicalSummaryRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }

  static const String malformedResponse =
      'Klinik özetler yüklenirken bir sorun oluştu.';

  static const String genericLoadFailure = malformedResponse;
}
