import 'prescription_repository_failure.dart';

abstract final class PrescriptionUserMessages {
  static const genericLoadFailure = 'Reçeteler yüklenemedi.';
  static const genericSaveFailure = 'Reçete kaydedilemedi.';
  static const notFound = 'Reçete bulunamadı.';

  static String forFailure(PrescriptionRepositoryFailure reason) {
    switch (reason) {
      case PrescriptionRepositoryFailure.notConfigured:
      case PrescriptionRepositoryFailure.noActiveTenant:
        return 'Reçeteler için uzak bağlantı hazır değil.';
      case PrescriptionRepositoryFailure.forbidden:
        return 'Reçetelere erişim yetkiniz yok.';
      case PrescriptionRepositoryFailure.notFound:
        return notFound;
      case PrescriptionRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle reçeteler yüklenemedi.';
      case PrescriptionRepositoryFailure.invalidRow:
        return 'Reçete verisi beklenen formatta değil.';
      case PrescriptionRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
