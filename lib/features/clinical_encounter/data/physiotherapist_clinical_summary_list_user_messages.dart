import 'physiotherapist_clinical_summary_repository_failure.dart';

/// FTR klinik özet listesi — kullanıcı mesajları.
abstract final class PhysiotherapistClinicalSummaryListUserMessages {
  static const String loading = 'FTR klinik özetleri yükleniyor…';
  static const String emptyGeneric =
      'Görüntülenebilecek FTR klinik özeti bulunamadı.';
  static const String emptyForPatient =
      'Bu hasta için görüntülenebilecek FTR klinik özeti bulunamadı.';
  static const String errorTitle = 'FTR klinik özetleri yüklenemedi';

  static const String notConfigured =
      'FTR klinik özetleri şu anda görüntülenemiyor.';
  static const String notConfiguredDescription =
      'FTR güvenli özet modülü henüz bu ortamda etkin değil. '
      'Oturum hazır olduğunda burada listelenecek.';

  static String forFailure(PhysiotherapistClinicalSummaryRepositoryFailure reason) {
    switch (reason) {
      case PhysiotherapistClinicalSummaryRepositoryFailure.noActiveTenant:
        return 'FTR klinik özetlerine erişmek için aktif klinik oturumu gerekli.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.forbidden:
        return 'Bu FTR klinik özetini görüntüleme yetkiniz bulunmuyor.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.network:
        return 'FTR klinik özetleri yüklenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.notConfigured:
        return 'FTR klinik özetleri şu anda görüntülenemiyor.';
      case PhysiotherapistClinicalSummaryRepositoryFailure.notFound:
        return emptyGeneric;
      case PhysiotherapistClinicalSummaryRepositoryFailure.invalidRow:
        return malformedResponse;
      case PhysiotherapistClinicalSummaryRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }

  static const String malformedResponse =
      'FTR klinik özetleri yüklenirken bir sorun oluştu.';

  static const String genericLoadFailure = malformedResponse;
}
