import 'post_op_protocol_repository_failure.dart';

abstract final class PostOpProtocolUserMessages {
  static const genericLoadFailure = 'Post-op protokoller yüklenemedi.';
  static const genericSaveFailure = 'Post-op protokol kaydedilemedi.';
  static const notFound = 'Post-op protokol bulunamadı.';

  static String forFailure(PostOpProtocolRepositoryFailure reason) {
    switch (reason) {
      case PostOpProtocolRepositoryFailure.notConfigured:
      case PostOpProtocolRepositoryFailure.noActiveTenant:
        return 'Post-op protokoller için uzak bağlantı hazır değil.';
      case PostOpProtocolRepositoryFailure.forbidden:
        return 'Post-op protokollere erişim yetkiniz yok.';
      case PostOpProtocolRepositoryFailure.notFound:
        return notFound;
      case PostOpProtocolRepositoryFailure.network:
        return 'Bağlantı sorunu nedeniyle post-op protokoller yüklenemedi.';
      case PostOpProtocolRepositoryFailure.invalidRow:
        return 'Post-op protokol verisi beklenen formatta değil.';
      case PostOpProtocolRepositoryFailure.unknown:
        return genericLoadFailure;
    }
  }
}
