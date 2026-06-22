import 'lab_order_template_repository_failure.dart';

abstract final class LabOrderTemplateUserMessages {
  static const genericLoadFailure = 'Laboratuvar şablonları yüklenemedi.';
  static const genericSaveFailure = 'Laboratuvar şablonu kaydedilemedi.';
  static const genericDeleteFailure = 'Laboratuvar şablonu silinemedi.';
  static const notFound = 'Laboratuvar şablonu bulunamadı.';

  static String forFailure(LabOrderTemplateRepositoryFailure reason) {
    switch (reason) {
      case LabOrderTemplateRepositoryFailure.notConfigured:
      case LabOrderTemplateRepositoryFailure.noActiveTenant:
        return 'Laboratuvar şablonları için uzak bağlantı hazır değil.';
      case LabOrderTemplateRepositoryFailure.forbidden:
        return 'Laboratuvar şablonlarına erişim yetkiniz yok.';
      case LabOrderTemplateRepositoryFailure.notFound:
        return notFound;
      case LabOrderTemplateRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle laboratuvar şablonları yüklenemedi.';
      case LabOrderTemplateRepositoryFailure.invalidRow:
        return 'Laboratuvar şablonu verisi beklenen formatta değil.';
      case LabOrderTemplateRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
