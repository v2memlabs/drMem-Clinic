import 'dart:typed_data';

import 'settings_image_storage_repository.dart';

/// Mock branding storage — bellekte path→bytes; upsert destekli.
class MockSettingsImageStorageRepository implements SettingsImageStorageRepository {
  static final Map<String, Uint8List> pathToBytes = {};

  static void clearAll() {
    pathToBytes.clear();
  }

  String _key(String bucket, String path) => '$bucket::$path';

  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String mimeType,
    bool upsert = true,
  }) async {
    if (bytes.isEmpty) {
      throw const SettingsImageStorageException('Dosya boş olamaz.');
    }
    final key = _key(bucket, path);
    if (!upsert && pathToBytes.containsKey(key)) {
      throw const SettingsImageStorageException('Bu dosya yolu zaten kullanılıyor.');
    }
    pathToBytes[key] = Uint8List.fromList(bytes);
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = SettingsImageStorageRepository.signedUrlExpiresInSeconds,
  }) async {
    final key = _key(bucket, path);
    if (!pathToBytes.containsKey(key)) {
      throw const SettingsImageStorageException('Dosya bulunamadı.');
    }
    return 'drmem-mock://settings-image/$key?ttl=$expiresInSeconds';
  }

  @override
  Future<Uint8List?> downloadBytes({
    required String bucket,
    required String path,
  }) async {
    return pathToBytes[_key(bucket, path)];
  }

  static Uint8List? bytesForMockUrl(String url) {
    const prefix = 'drmem-mock://settings-image/';
    if (!url.startsWith(prefix)) return null;
    final rest = url.substring(prefix.length);
    final key = rest.split('?').first;
    return pathToBytes[key];
  }
}
