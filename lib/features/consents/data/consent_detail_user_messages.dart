import 'consent_repository_failure.dart';

abstract final class ConsentDetailUserMessages {
  static const String loading = 'Onam kaydı yükleniyor…';
  static const String notFoundTitle = 'Onam kaydı bulunamadı';
  static const String notFoundDescription =
      'Kayıt silinmiş veya erişim yetkiniz değişmiş olabilir.';
  static const String errorTitle = 'Onam kaydı yüklenemedi';
  static const String genericLoadFailure =
      'Onam detayı yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(ConsentRepositoryFailure reason) {
    switch (reason) {
      case ConsentRepositoryFailure.forbidden:
        return 'Bu onam kaydına erişim yetkiniz bulunmuyor.';
      case ConsentRepositoryFailure.noActiveTenant:
        return 'Onam detayı için aktif klinik oturumu gerekli.';
      case ConsentRepositoryFailure.notConfigured:
        return 'Onam detayı şu anda görüntülenemiyor.';
      case ConsentRepositoryFailure.network:
        return 'Onam detayı yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case ConsentRepositoryFailure.notFound:
        return notFoundDescription;
      case ConsentRepositoryFailure.invalidRow:
      case ConsentRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
