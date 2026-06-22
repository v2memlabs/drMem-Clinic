import 'dart:typed_data';

import 'settings_image_storage_repository.dart';

class SettingsImageStorageRepositoryStub
    implements SettingsImageStorageRepository {
  const SettingsImageStorageRepositoryStub();

  Never _notConfigured() => throw const SettingsImageStorageException(
        'Görsel yükleme şu anda kullanıma hazır değil.',
      );

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds =
        SettingsImageStorageRepository.signedUrlExpiresInSeconds,
  }) async =>
      _notConfigured();

  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String mimeType,
    bool upsert = true,
  }) async =>
      _notConfigured();

  @override
  Future<Uint8List?> downloadBytes({
    required String bucket,
    required String path,
  }) async =>
      _notConfigured();
}
