import 'lab_order_repository_failure.dart';

abstract final class LabOrderUserMessages {
  static const genericLoadFailure = 'Laboratuvar istemleri yüklenemedi.';
  static const genericSaveFailure = 'Laboratuvar istemi kaydedilemedi.';
  static const genericDeleteFailure = 'Laboratuvar istemi silinemedi.';
  static const notFound = 'Laboratuvar istemi bulunamadı.';

  static String forFailure(LabOrderRepositoryFailure reason) {
    switch (reason) {
      case LabOrderRepositoryFailure.notConfigured:
      case LabOrderRepositoryFailure.noActiveTenant:
        return 'Laboratuvar istemleri için uzak bağlantı hazır değil.';
      case LabOrderRepositoryFailure.forbidden:
        return 'Laboratuvar istemlerine erişim yetkiniz yok.';
      case LabOrderRepositoryFailure.notFound:
        return notFound;
      case LabOrderRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle laboratuvar istemleri yüklenemedi.';
      case LabOrderRepositoryFailure.invalidRow:
        return 'Laboratuvar istemi verisi beklenen formatta değil.';
      case LabOrderRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
