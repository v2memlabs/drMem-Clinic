import 'sent_message_repository_failure.dart';

abstract final class SentMessageUserMessages {
  static const genericLoadFailure = 'Gönderim kayıtları yüklenemedi.';
  static const genericSaveFailure = 'Gönderim kaydı oluşturulamadı.';
  static const notFound = 'Gönderim kaydı bulunamadı.';

  static String forFailure(SentMessageRepositoryFailure reason) {
    switch (reason) {
      case SentMessageRepositoryFailure.notConfigured:
      case SentMessageRepositoryFailure.noActiveTenant:
        return 'Gönderim kayıtları için uzak bağlantı hazır değil.';
      case SentMessageRepositoryFailure.forbidden:
        return 'Gönderim kayıtlarına erişim yetkiniz yok.';
      case SentMessageRepositoryFailure.notFound:
        return notFound;
      case SentMessageRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle gönderim kayıtları yüklenemedi.';
      case SentMessageRepositoryFailure.invalidRow:
        return 'Gönderim kaydı verisi beklenen formatta değil.';
      case SentMessageRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
