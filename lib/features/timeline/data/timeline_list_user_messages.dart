import 'timeline_list_failure_presentation.dart';
import 'timeline_repository_failure.dart';

/// Hasta timeline listesi — kullanıcı mesajları (teknik detay yok).
abstract final class TimelineListUserMessages {
  static const String loading = 'Hasta geçmişi yükleniyor…';

  static const String emptyForPatient =
      'Bu hasta için gösterilecek timeline kaydı bulunamadı.';
  static const String emptyForPatientDescription =
      'Randevu, muayene, dosya ve diğer klinik olaylar kaydedildikçe burada listelenecek.';

  static const String filterNoMatch =
      'Arama veya filtre kriterlerinize uygun olay yok.';
  static const String filterNoMatchDescription =
      'Farklı bir arama veya olay tipi deneyin.';

  static const String notConfigured =
      'Hasta geçmişi şu anda görüntülenemiyor.';
  static const String notConfiguredDescription =
      'Hasta geçmişi henüz etkin değil. Kayıtlar etkinleştirildiğinde burada listelenecek.';

  static const String sessionRequired =
      'Hasta geçmişine erişmek için aktif klinik oturumu gerekli.';
  static const String sessionRequiredDescription =
      'Lütfen klinik seçimini tamamlayıp tekrar deneyin.';

  static const String forbidden =
      'Bu hasta geçmişini görüntüleme yetkiniz bulunmuyor.';
  static const String forbiddenDescription =
      'Yetkinizle uyumlu kayıtlar görüntülenir.';

  static const String networkError =
      'Hasta geçmişi yüklenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin.';
  static const String invalidRowError =
      'Hasta geçmişi yüklenirken veri biçimiyle ilgili bir sorun oluştu.';
  static const String genericError =
      'Hasta geçmişi yüklenirken bir sorun oluştu.';
  static const String genericErrorDescription =
      'Lütfen kısa süre sonra tekrar deneyin.';

  static const String errorTitle = 'Hasta geçmişi yüklenemedi';

  static const String requiresPatientContext =
      'Hasta geçmişi görüntülemek için hasta bağlamı gerekli.';
  static const String requiresPatientContextDescription =
      'Hasta detayından zaman çizelgesine geçin.';

  static const String navigationUnavailable =
      'Bu kayda geçiş henüz kullanılamıyor.';

  /// @deprecated Use [presentationForFailure] description fields.
  static const String errorDescription = networkError;

  static TimelineListFailurePresentation presentationForFailure(
    TimelineRepositoryFailure reason,
  ) {
    switch (reason) {
      case TimelineRepositoryFailure.notConfigured:
        return const TimelineListFailurePresentation(
          title: notConfigured,
          description: notConfiguredDescription,
          showRetry: false,
        );
      case TimelineRepositoryFailure.noActiveTenant:
        return const TimelineListFailurePresentation(
          title: sessionRequired,
          description: sessionRequiredDescription,
          showRetry: true,
        );
      case TimelineRepositoryFailure.forbidden:
        return const TimelineListFailurePresentation(
          title: forbidden,
          description: forbiddenDescription,
          showRetry: false,
        );
      case TimelineRepositoryFailure.network:
        return const TimelineListFailurePresentation(
          title: errorTitle,
          description: networkError,
          showRetry: true,
        );
      case TimelineRepositoryFailure.invalidRow:
        return const TimelineListFailurePresentation(
          title: errorTitle,
          description: invalidRowError,
          showRetry: true,
        );
      case TimelineRepositoryFailure.notFound:
        return const TimelineListFailurePresentation(
          title: emptyForPatient,
          description: emptyForPatientDescription,
          showRetry: false,
        );
      case TimelineRepositoryFailure.invalidInput:
      case TimelineRepositoryFailure.unknown:
        return const TimelineListFailurePresentation(
          title: errorTitle,
          description: genericErrorDescription,
          showRetry: true,
        );
    }
  }

  static TimelineListFailurePresentation genericFailurePresentation() {
    return const TimelineListFailurePresentation(
      title: errorTitle,
      description: genericErrorDescription,
      showRetry: true,
    );
  }

  /// @deprecated Use [presentationForFailure].
  static String forFailure(TimelineRepositoryFailure reason) {
    return presentationForFailure(reason).description.isNotEmpty
        ? presentationForFailure(reason).description
        : presentationForFailure(reason).title;
  }
}
