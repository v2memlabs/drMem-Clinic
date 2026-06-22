import 'dart:typed_data';

import '../../../core/auth/auth_session.dart';
import 'patient_file_metadata_repository_provider.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/patient_file_metadata.dart';
import '../models/patient_file_metadata_enums.dart';
import 'patient_file_metadata_access_gate.dart';
import 'patient_file_metadata_create_input.dart';
import 'patient_file_metadata_repository.dart';
import 'patient_file_storage_id.dart';
import 'patient_file_storage_path_builder.dart';
import 'patient_file_storage_repository.dart';
import 'patient_file_storage_repository_provider.dart';

/// Upload: storage → metadata; metadata fail → storage rollback.
abstract final class PatientFileUploadOrchestrator {
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  static const Set<String> allowedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/png',
  };

  static Future<PatientFileMetadata> uploadPatientFile({
    required String patientId,
    required Uint8List bytes,
    required String mimeType,
    required String originalFileName,
    PatientFileKind fileKind = PatientFileKind.patientUpload,
    PatientFileClinicalContext clinicalContext =
        PatientFileClinicalContext.patient,
    PatientFileVisibilityScope visibilityScope =
        PatientFileVisibilityScope.clinicOperations,
    String? encounterId,
    String? appointmentId,
    Map<String, Object?>? metadata,
  }) async {
    final pid = patientId.trim();
    if (pid.isEmpty) {
      throw const PatientFileUploadException('Hasta seçimi gerekli.');
    }

    if (ActiveTenantContextStore.current?.tenantId == null) {
      throw const PatientFileUploadException('Aktif klinik bulunamadı.');
    }

    if (!PatientFileMetadataAccessGate.canUploadForScope(visibilityScope)) {
      throw const PatientFileUploadException('Bu dosyaya erişim yetkiniz yok.');
    }

    final normalizedMime = mimeType.trim().toLowerCase();
    if (!allowedMimeTypes.contains(normalizedMime)) {
      throw const PatientFileUploadException(
        'Yalnızca PDF veya görüntü dosyası yüklenebilir.',
      );
    }

    if (bytes.isEmpty || bytes.length > maxFileSizeBytes) {
      throw const PatientFileUploadException(
        'Dosya boyutu geçersiz veya izin verilen sınırı aşıyor.',
      );
    }

    final tenantId = ActiveTenantContextStore.current!.tenantId;
    final fileId = generatePatientFileStorageId();
    final storagePath = PatientFileStoragePathBuilder.patientUploadPath(
      tenantId: tenantId,
      patientId: pid,
      fileId: fileId,
      safeSegment: originalFileName,
    );
    const bucket = PatientFileStoragePathBuilder.defaultBucket;

    final storage = PatientFileStorageRepositoryProvider.repository;
    final metadataRepo = PatientFileMetadataRepositoryProvider.repository;

    try {
      await storage.upload(
        bucket: bucket,
        path: storagePath,
        bytes: bytes,
        mimeType: normalizedMime,
      );
    } on PatientFileStorageException {
      throw const PatientFileUploadException('Dosya güvenli alana yüklenemedi.');
    }

    final displayName = _displayNameFromOriginal(originalFileName);

    try {
      return await metadataRepo.createPatientFileMetadata(
        PatientFileMetadataCreateInput(
          patientId: pid,
          fileKind: fileKind,
          clinicalContext: clinicalContext,
          displayName: displayName,
          storagePath: storagePath,
          storageBucket: bucket,
          originalFileName: originalFileName,
          mimeType: normalizedMime,
          fileSizeBytes: bytes.length,
          visibilityScope: visibilityScope,
          encounterId: encounterId,
          appointmentId: appointmentId,
          metadata: metadata,
        ),
      );
    } on Object {
      await storage.remove(bucket: bucket, path: storagePath);
      throw const PatientFileUploadException('Dosya kaydı oluşturulamadı.');
    }
  }

  static String _displayNameFromOriginal(String original) {
    final name = original.trim();
    if (name.isEmpty) return 'Hasta dosyası';
    final slash = name.replaceAll('\\', '/');
    final segment = slash.contains('/') ? slash.split('/').last : slash;
    return segment.isEmpty ? 'Hasta dosyası' : segment;
  }
}

class PatientFileUploadException implements Exception {
  const PatientFileUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
