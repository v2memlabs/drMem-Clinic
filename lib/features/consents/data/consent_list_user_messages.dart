import 'consent_repository_failure.dart';

abstract final class ConsentListUserMessages {
  static const String loading = 'Onam kayıtları yükleniyor…';
  static const String errorTitle = 'Onam kayıtları yüklenemedi';
  static const String genericLoadFailure =
      'Onam kayıtları yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(ConsentRepositoryFailure reason) {
    switch (reason) {
      case ConsentRepositoryFailure.forbidden:
        return 'Onam kayıtlarına erişim yetkiniz bulunmuyor.';
      case ConsentRepositoryFailure.noActiveTenant:
        return 'Onam kayıtları için aktif klinik oturumu gerekli.';
      case ConsentRepositoryFailure.notConfigured:
        return 'Onam kayıtları şu anda görüntülenemiyor.';
      case ConsentRepositoryFailure.network:
        return 'Onam kayıtları yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case ConsentRepositoryFailure.notFound:
      case ConsentRepositoryFailure.invalidRow:
      case ConsentRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
