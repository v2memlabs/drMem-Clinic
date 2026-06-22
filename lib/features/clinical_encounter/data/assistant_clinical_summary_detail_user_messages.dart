import 'assistant_clinical_summary_list_user_messages.dart';
import 'assistant_clinical_summary_repository_failure.dart';

/// Assistant klinik özet detay — kullanıcı mesajları.
abstract final class AssistantClinicalSummaryDetailUserMessages {
  static const String shellTitle = 'Tanı Özeti';
  static const String loading = 'Klinik özet yükleniyor…';
  static const String notFoundTitle = 'Klinik özet bulunamadı';
  static const String notFound =
      'İstenen klinik özet kaydı bulunamadı veya erişim yok.';
  static const String errorTitle = 'Klinik özet yüklenemedi';

  static String forFailure(AssistantClinicalSummaryRepositoryFailure reason) {
    switch (reason) {
      case AssistantClinicalSummaryRepositoryFailure.noActiveTenant:
        return 'Klinik özetlere erişmek için aktif klinik oturumu gerekli.';
      case AssistantClinicalSummaryRepositoryFailure.forbidden:
        return 'Bu klinik özeti görüntüleme yetkiniz bulunmuyor.';
      case AssistantClinicalSummaryRepositoryFailure.network:
        return 'Klinik özet yüklenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
      case AssistantClinicalSummaryRepositoryFailure.notConfigured:
        return 'Klinik özet şu anda görüntülenemiyor.';
      case AssistantClinicalSummaryRepositoryFailure.notFound:
        return notFound;
      case AssistantClinicalSummaryRepositoryFailure.invalidRow:
        return AssistantClinicalSummaryListUserMessages.malformedResponse;
      case AssistantClinicalSummaryRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }

  static const String genericLoadFailure =
      'Klinik özet yüklenirken bir sorun oluştu.';
}
