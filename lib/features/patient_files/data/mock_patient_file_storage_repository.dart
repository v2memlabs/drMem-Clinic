import 'dart:convert';
import 'dart:typed_data';

import 'patient_file_storage_repository.dart';

/// Mock private storage — bellekte path→bytes; signed URL mock scheme.
class MockPatientFileStorageRepository implements PatientFileStorageRepository {
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
    bool upsert = false,
  }) async {
    if (bytes.isEmpty) {
      throw const PatientFileStorageException('Dosya boş olamaz.');
    }
    final key = _key(bucket, path);
    if (!upsert && pathToBytes.containsKey(key)) {
      throw const PatientFileStorageException('Bu dosya yolu zaten kullanılıyor.');
    }
    pathToBytes[key] = Uint8List.fromList(bytes);
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = PatientFileStorageRepository.signedUrlExpiresInSeconds,
  }) async {
    final key = _key(bucket, path);
    if (!pathToBytes.containsKey(key)) {
      throw const PatientFileStorageException('Dosya bulunamadı.');
    }
    final encoded = base64Url.encode(utf8.encode('$bucket/$path'));
    return 'drmem-mock://patient-file/$encoded?ttl=$expiresInSeconds';
  }

  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async {
    pathToBytes.remove(_key(bucket, path));
  }

  @override
  Future<Uint8List> download({
    required String bucket,
    required String path,
  }) async {
    final key = _key(bucket, path);
    final bytes = pathToBytes[key];
    if (bytes == null) {
      throw const PatientFileStorageException('Dosya bulunamadı.');
    }
    return Uint8List.fromList(bytes);
  }
}
