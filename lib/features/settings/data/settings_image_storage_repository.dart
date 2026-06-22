import 'dart:typed_data';

abstract interface class SettingsImageStorageRepository {
  static const int signedUrlExpiresInSeconds = 3600;

  Future<void> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String mimeType,
    bool upsert = true,
  });

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = signedUrlExpiresInSeconds,
  });

  Future<Uint8List?> downloadBytes({
    required String bucket,
    required String path,
  });
}

class SettingsImageStorageException implements Exception {
  const SettingsImageStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
