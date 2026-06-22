import 'radiology_order_repository_failure.dart';

abstract final class RadiologyOrderUserMessages {
  static const genericLoadFailure = 'Radyoloji istemleri yüklenemedi.';
  static const genericSaveFailure = 'Radyoloji istemi kaydedilemedi.';
  static const genericDeleteFailure = 'Radyoloji istemi silinemedi.';
  static const notFound = 'Radyoloji istemi bulunamadı.';

  static String forFailure(RadiologyOrderRepositoryFailure reason) {
    switch (reason) {
      case RadiologyOrderRepositoryFailure.notConfigured:
      case RadiologyOrderRepositoryFailure.noActiveTenant:
        return 'Radyoloji istemleri için uzak bağlantı hazır değil.';
      case RadiologyOrderRepositoryFailure.forbidden:
        return 'Radyoloji istemlerine erişim yetkiniz yok.';
      case RadiologyOrderRepositoryFailure.notFound:
        return notFound;
      case RadiologyOrderRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle radyoloji istemleri yüklenemedi.';
      case RadiologyOrderRepositoryFailure.invalidRow:
        return 'Radyoloji istemi verisi beklenen formatta değil.';
      case RadiologyOrderRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
