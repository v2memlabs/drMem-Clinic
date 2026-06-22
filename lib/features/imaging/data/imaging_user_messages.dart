import 'imaging_repository_failure.dart';

abstract final class ImagingUserMessages {
  static const genericLoadFailure = 'Görüntüleme notları yüklenemedi.';
  static const genericSaveFailure = 'Görüntüleme notu kaydedilemedi.';
  static const notFound = 'Görüntüleme notu bulunamadı.';

  static String forFailure(ImagingRepositoryFailure reason) {
    switch (reason) {
      case ImagingRepositoryFailure.notConfigured:
      case ImagingRepositoryFailure.noActiveTenant:
        return 'Görüntüleme notları için uzak bağlantı hazır değil.';
      case ImagingRepositoryFailure.forbidden:
        return 'Görüntüleme notlarına erişim yetkiniz yok.';
      case ImagingRepositoryFailure.notFound:
        return notFound;
      case ImagingRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle görüntüleme notları yüklenemedi.';
      case ImagingRepositoryFailure.invalidRow:
        return 'Görüntüleme notu verisi beklenen formatta değil.';
      case ImagingRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
