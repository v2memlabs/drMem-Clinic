import 'dart:typed_data';

/// Private bucket binary işlemleri — metadata ayrı repository'de.
abstract interface class PatientFileStorageRepository {
  static const int signedUrlExpiresInSeconds = 120;

  Future<void> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String mimeType,
    bool upsert = false,
  });

  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = signedUrlExpiresInSeconds,
  });

  Future<void> remove({
    required String bucket,
    required String path,
  });

  Future<Uint8List> download({
    required String bucket,
    required String path,
  });
}

class PatientFileStorageException implements Exception {
  const PatientFileStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}
