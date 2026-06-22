import 'payment_repository_failure.dart';

abstract final class PaymentListUserMessages {
  static const String loading = 'Ödeme kayıtları yükleniyor…';
  static const String errorTitle = 'Ödeme kayıtları yüklenemedi';
  static const String genericLoadFailure =
      'Ödeme kayıtları yüklenemedi. Lütfen tekrar deneyin.';

  static String forFailure(PaymentRepositoryFailure reason) {
    switch (reason) {
      case PaymentRepositoryFailure.forbidden:
        return 'Ödeme kayıtlarına erişim yetkiniz bulunmuyor.';
      case PaymentRepositoryFailure.noActiveTenant:
        return 'Ödeme kayıtları için aktif klinik oturumu gerekli.';
      case PaymentRepositoryFailure.notConfigured:
        return 'Ödeme kayıtları şu anda görüntülenemiyor.';
      case PaymentRepositoryFailure.network:
        return 'Ödeme kayıtları yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';
      case PaymentRepositoryFailure.notFound:
      case PaymentRepositoryFailure.invalidRow:
      case PaymentRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
