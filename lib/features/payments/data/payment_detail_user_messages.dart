import 'payment_repository_failure.dart';

abstract final class PaymentDetailUserMessages {
  static const String loading = 'Ödeme kaydı yükleniyor…';
  static const String notFoundTitle = 'Ödeme kaydı bulunamadı';
  static const String notFoundDescription =
      'Kayıt silinmiş veya erişim yetkiniz değişmiş olabilir.';
  static const String errorTitle = 'Ödeme kaydı yüklenemedi';
  static const String genericLoadFailure =
      'Ödeme detayı yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(PaymentRepositoryFailure reason) {
    switch (reason) {
      case PaymentRepositoryFailure.forbidden:
        return 'Bu ödeme kaydına erişim yetkiniz bulunmuyor.';
      case PaymentRepositoryFailure.noActiveTenant:
        return 'Ödeme detayı için aktif klinik oturumu gerekli.';
      case PaymentRepositoryFailure.notConfigured:
        return 'Ödeme detayı şu anda görüntülenemiyor.';
      case PaymentRepositoryFailure.network:
        return 'Ödeme detayı yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case PaymentRepositoryFailure.notFound:
        return notFoundDescription;
      case PaymentRepositoryFailure.invalidRow:
      case PaymentRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
