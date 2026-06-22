import '../models/patient_file_metadata_enums.dart';
import 'patient_file_metadata_create_input.dart';
import 'patient_file_metadata_sanitizer.dart';

/// `patient_files` tablosu — insert/update/select map (metadata only).
abstract final class PatientFileMetadataRemoteMapper {
  static const String table = 'patient_files';

  static const String selectColumns =
      'id, tenant_id, patient_id, created_by, file_name, file_type, mime_type, '
      'size_bytes, storage_bucket, storage_path, file_kind, clinical_context, '
      'encounter_id, appointment_id, display_name, original_file_name, checksum, '
      'status, visibility_scope, metadata, created_at, updated_at, deleted_at';

  /// Insert — `tenant_id` scope'tan; id/timestamp/deleted_at gönderilmez.
  static Map<String, dynamic> toInsertRow({
    required PatientFileMetadataCreateInput input,
    required String tenantId,
    String? createdByProfileId,
  }) {
    input.validate();

    final displayName = input.displayName.trim();
    final metadata = PatientFileMetadataSanitizer.sanitize(input.metadata);

    return {
      'tenant_id': tenantId,
      'patient_id': input.patientId.trim(),
      if (createdByProfileId != null && createdByProfileId.trim().isNotEmpty)
        'created_by': createdByProfileId.trim(),
      'file_name': displayName,
      'file_type': input.mimeType?.trim() ?? input.fileKind.dbValue,
      if (input.mimeType != null && input.mimeType!.trim().isNotEmpty)
        'mime_type': input.mimeType!.trim(),
      if (input.fileSizeBytes != null) 'size_bytes': input.fileSizeBytes,
      'storage_bucket': input.storageBucket.trim(),
      'storage_path': input.storagePath.trim(),
      'file_kind': input.fileKind.dbValue,
      'clinical_context': input.clinicalContext.dbValue,
      if (input.encounterId != null && input.encounterId!.trim().isNotEmpty)
        'encounter_id': input.encounterId!.trim(),
      if (input.appointmentId != null && input.appointmentId!.trim().isNotEmpty)
        'appointment_id': input.appointmentId!.trim(),
      'display_name': displayName,
      if (input.originalFileName != null &&
          input.originalFileName!.trim().isNotEmpty)
        'original_file_name': input.originalFileName!.trim(),
      if (input.checksum != null && input.checksum!.trim().isNotEmpty)
        'checksum': input.checksum!.trim(),
      'status': PatientFileStatus.active.dbValue,
      'visibility_scope': input.visibilityScope.dbValue,
      'metadata': metadata,
    };
  }

  /// Soft archive — physical delete yok.
  static Map<String, dynamic> toArchiveRow({DateTime? at}) {
    final when = (at ?? DateTime.now()).toUtc();
    return {
      'status': PatientFileStatus.archived.dbValue,
      'deleted_at': when.toIso8601String(),
      'updated_at': when.toIso8601String(),
    };
  }
}
