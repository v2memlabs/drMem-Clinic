import 'consent_list_user_messages.dart';
import 'consent_repository_failure.dart';

abstract final class ConsentTemplateListUserMessages {
  static const String loading = 'Onam şablonları yükleniyor…';
  static const String errorTitle = 'Onam şablonları yüklenemedi';
  static const String genericLoadFailure =
      'Onam şablonları yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(ConsentRepositoryFailure reason) {
    switch (reason) {
      case ConsentRepositoryFailure.forbidden:
        return 'Onam şablonlarına erişim yetkiniz bulunmuyor.';
      case ConsentRepositoryFailure.noActiveTenant:
        return 'Onam şablonları için aktif klinik oturumu gerekli.';
      case ConsentRepositoryFailure.notConfigured:
        return 'Onam şablonları şu anda görüntülenemiyor.';
      case ConsentRepositoryFailure.network:
        return 'Onam şablonları yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case ConsentRepositoryFailure.notFound:
      case ConsentRepositoryFailure.invalidRow:
      case ConsentRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }

  static String saveFailure(ConsentRepositoryFailure reason) {
    return ConsentListUserMessages.forFailure(reason);
  }
}
