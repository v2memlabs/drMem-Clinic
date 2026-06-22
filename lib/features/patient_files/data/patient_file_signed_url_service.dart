import 'patient_file_metadata_repository_provider.dart';
import '../models/patient_file_metadata.dart';
import 'patient_file_metadata_access_gate.dart';
import 'patient_file_metadata_repository_failure.dart'
    show PatientFileMetadataRepositoryException;
import 'patient_file_storage_repository.dart';
import 'patient_file_storage_repository_provider.dart';

/// Kısa ömürlü signed URL — metadata RLS + scope sonrası.
abstract final class PatientFileSignedUrlService {
  static const int expiresInSeconds =
      PatientFileStorageRepository.signedUrlExpiresInSeconds;

  static Future<String> createViewUrlForPatientFile(String fileId) async {
    final meta = await _loadAuthorizedMetadata(fileId);
    return PatientFileStorageRepositoryProvider.repository.createSignedUrl(
      bucket: meta.storageBucket,
      path: meta.storagePath,
      expiresInSeconds: expiresInSeconds,
    );
  }

  static Future<PatientFileMetadata> _loadAuthorizedMetadata(String fileId) async {
    final id = fileId.trim();
    if (id.isEmpty) {
      throw const PatientFileSignedUrlException(
        'Bu dosyaya erişim yetkiniz yok.',
      );
    }

    PatientFileMetadata? meta;
    try {
      meta = await PatientFileMetadataRepositoryProvider.repository
          .getPatientFileMetadata(id);
    } on PatientFileMetadataRepositoryException catch (_) {
      throw const PatientFileSignedUrlException(
        'Dosya açılırken bir sorun oluştu.',
      );
    }

    if (meta == null || !PatientFileMetadataAccessGate.canView(meta)) {
      throw const PatientFileSignedUrlException(
        'Bu dosyaya erişim yetkiniz yok.',
      );
    }

    return meta;
  }
}

class PatientFileSignedUrlException implements Exception {
  const PatientFileSignedUrlException(this.message);

  final String message;

  @override
  String toString() => message;
}
