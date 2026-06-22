import 'physiotherapist_clinical_summary_list_user_messages.dart';
import 'physiotherapist_clinical_summary_repository_failure.dart';

/// FTR klinik özet detay — kullanıcı mesajları.
abstract final class PhysiotherapistClinicalSummaryDetailUserMessages {
  static const String shellTitle = 'Klinik Özet';
  static const String loading = 'FTR klinik özeti yükleniyor…';
  static const String notFoundTitle = 'FTR klinik özeti bulunamadı';
  static const String notFound =
      'İstenen FTR klinik özeti kaydı bulunamadı veya erişim yok.';
  static const String errorTitle = 'FTR klinik özeti yüklenemedi';

  static String forFailure(PhysiotherapistClinicalSummaryRepositoryFailure reason) {
    switch (reason) {
      case PhysiotherapistClinicalSummaryRepositoryFailure.noActiveTenant:
        return 'FTR klinik özetlerine erişmek için aktif klinik oturumu gerekli.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.forbidden:
        return 'Bu FTR klinik özetini görüntüleme yetkiniz bulunmuyor.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.network:
        return 'FTR klinik özeti yüklenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.notConfigured:
        return 'FTR klinik özeti şu anda görüntülenemiyor.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.notFound:
        return notFound;
      case PhysiotherapistClinicalSummaryRepositoryFailure.invalidRow:
        return PhysiotherapistClinicalSummaryListUserMessages.malformedResponse;
      case PhysiotherapistClinicalSummaryRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }

  static const String genericLoadFailure =
      'FTR klinik özeti yüklenirken bir sorun oluştu.';
}
