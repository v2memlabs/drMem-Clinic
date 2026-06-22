import '../models/patient_file_metadata.dart';
import '../models/patient_file_metadata_enums.dart';
import 'patient_file_metadata_dto.dart';
import 'patient_file_metadata_repository_failure.dart';
import 'patient_file_metadata_sanitizer.dart';

/// `PatientFileMetadataDto` → [PatientFileMetadata].
///
/// Allowlist metadata only — no file/PDF binary, no clinical raw fields.
abstract final class PatientFileMetadataMapper {
  static const String defaultDisplayName = 'Dosya';

  static PatientFileMetadata fromDto(PatientFileMetadataDto dto) {
    final displayName = dto.displayName.trim();
    if (dto.storageBucket.trim().isEmpty || dto.storagePath.trim().isEmpty) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidRow,
      );
    }

    return PatientFileMetadata(
      id: dto.id,
      tenantId: dto.tenantId,
      patientId: dto.patientId,
      createdByUserId: dto.createdByUserId,
      fileKind: PatientFileKind.fromDbValue(dto.fileKind),
      clinicalContext: PatientFileClinicalContext.fromDbValue(dto.clinicalContext),
      encounterId: dto.encounterId,
      appointmentId: dto.appointmentId,
      physiotherapySessionId: dto.physiotherapySessionId,
      displayName:
          displayName.isEmpty ? defaultDisplayName : displayName,
      originalFileName: dto.originalFileName,
      mimeType: dto.mimeType,
      fileSizeBytes: dto.fileSizeBytes,
      storageBucket: dto.storageBucket.trim(),
      storagePath: dto.storagePath.trim(),
      checksum: dto.checksum,
      status: PatientFileStatus.fromDbValue(
        dto.status,
        allowPdfWorkflowAlias: dto.isGeneratedPdf,
      ),
      visibilityScope:
          PatientFileVisibilityScope.fromDbValue(dto.visibilityScope),
      metadata: Map<String, Object?>.unmodifiable(
        PatientFileMetadataSanitizer.sanitize(dto.metadata),
      ),
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      deletedAt: dto.deletedAt,
      isGeneratedPdf: dto.isGeneratedPdf,
    );
  }

  static PatientFileMetadata fromMap(Map<String, dynamic> map) {
    return fromDto(PatientFileMetadataDto.fromMap(map));
  }

  static PatientFileMetadata fromPatientFilesMap(Map<String, dynamic> map) {
    return fromDto(PatientFileMetadataDto.fromPatientFilesRow(map));
  }

  static PatientFileMetadata fromPdfOutputsMap(Map<String, dynamic> map) {
    return fromDto(PatientFileMetadataDto.fromPdfOutputsRow(map));
  }
}
