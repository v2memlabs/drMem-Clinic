import 'dart:typed_data';

import 'patient_file_storage_repository.dart';

class PatientFileStorageRepositoryStub implements PatientFileStorageRepository {
  const PatientFileStorageRepositoryStub();

  Never _notConfigured() => throw const PatientFileStorageException(
        'Dosya depolama şu anda kullanıma hazır değil.',
      );

  @override
  Future<void> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String mimeType,
    bool upsert = false,
  }) async =>
      _notConfigured();

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = PatientFileStorageRepository.signedUrlExpiresInSeconds,
  }) async =>
      _notConfigured();

  @override
  Future<void> remove({
    required String bucket,
    required String path,
  }) async =>
      _notConfigured();

  @override
  Future<Uint8List> download({
    required String bucket,
    required String path,
  }) async =>
      _notConfigured();
}
