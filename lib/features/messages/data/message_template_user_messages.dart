import 'message_template_repository_failure.dart';

abstract final class MessageTemplateUserMessages {
  static const genericLoadFailure = 'Mesaj şablonları yüklenemedi.';
  static const genericSaveFailure = 'Mesaj şablonu kaydedilemedi.';
  static const notFound = 'Mesaj şablonu bulunamadı.';

  static String forFailure(MessageTemplateRepositoryFailure reason) {
    switch (reason) {
      case MessageTemplateRepositoryFailure.notConfigured:
      case MessageTemplateRepositoryFailure.noActiveTenant:
        return 'Mesaj şablonları için uzak bağlantı hazır değil.';
      case MessageTemplateRepositoryFailure.forbidden:
        return 'Mesaj şablonlarına erişim yetkiniz yok.';
      case MessageTemplateRepositoryFailure.notFound:
        return notFound;
      case MessageTemplateRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle mesaj şablonları yüklenemedi.';
      case MessageTemplateRepositoryFailure.invalidRow:
        return 'Mesaj şablonu verisi beklenen formatta değil.';
      case MessageTemplateRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
