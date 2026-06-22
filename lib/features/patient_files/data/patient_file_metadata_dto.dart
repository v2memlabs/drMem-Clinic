import '../models/patient_file_metadata_enums.dart';
import 'patient_file_metadata_parse_helpers.dart';
import 'patient_file_metadata_repository_failure.dart';
import 'patient_file_metadata_sanitizer.dart';

/// `patient_files` / `pdf_outputs` satırı — allowlist metadata (içerik yok).
class PatientFileMetadataDto {
  final String id;
  final String tenantId;
  final String patientId;
  final String? createdByUserId;
  final String fileKind;
  final String clinicalContext;
  final String? encounterId;
  final String? appointmentId;
  final String? physiotherapySessionId;
  final String displayName;
  final String? originalFileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final String storageBucket;
  final String storagePath;
  final String? checksum;
  final String status;
  final String visibilityScope;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isGeneratedPdf;

  const PatientFileMetadataDto({
    required this.id,
    required this.tenantId,
    required this.patientId,
    this.createdByUserId,
    required this.fileKind,
    required this.clinicalContext,
    this.encounterId,
    this.appointmentId,
    this.physiotherapySessionId,
    required this.displayName,
    this.originalFileName,
    this.mimeType,
    this.fileSizeBytes,
    required this.storageBucket,
    required this.storagePath,
    this.checksum,
    required this.status,
    required this.visibilityScope,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isGeneratedPdf = false,
  });

  factory PatientFileMetadataDto.fromMap(Map<String, dynamic> map) {
    return PatientFileMetadataDto.fromPatientFilesRow(map);
  }

  factory PatientFileMetadataDto.fromPatientFilesRow(Map<String, dynamic> map) {
    try {
      return _fromRow(map, isGeneratedPdf: false);
    } on PatientFileMetadataRepositoryException {
      rethrow;
    } catch (_) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidRow,
      );
    }
  }

  factory PatientFileMetadataDto.fromPdfOutputsRow(Map<String, dynamic> map) {
    try {
      final meta = Map<String, Object?>.from(
        PatientFileMetadataSanitizer.sanitize(
          PatientFileMetadataParseHelpers.coerceMetadataMap(map['metadata']),
        ),
      );
      _mergePdfSourceMetadata(map, meta);

      return _fromRow(
        map,
        isGeneratedPdf: true,
        statusRaw: map['status']?.toString(),
        sizeBytes: PatientFileMetadataParseHelpers.optionalInt(
          map['file_size_bytes'],
        ),
        metadata: meta,
        allowPdfWorkflowStatus: true,
      );
    } on PatientFileMetadataRepositoryException {
      rethrow;
    } catch (_) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidRow,
      );
    }
  }

  static PatientFileMetadataDto _fromRow(
    Map<String, dynamic> map, {
    required bool isGeneratedPdf,
    String? statusRaw,
    int? sizeBytes,
    Map<String, Object?>? metadata,
    bool allowPdfWorkflowStatus = false,
  }) {
    final id = PatientFileMetadataParseHelpers.requireString(map, 'id');
    final tenantId =
        PatientFileMetadataParseHelpers.requireString(map, 'tenant_id');
    final patientId =
        PatientFileMetadataParseHelpers.requireString(map, 'patient_id');
    final storagePath =
        PatientFileMetadataParseHelpers.requireString(map, 'storage_path');

    final displayName = PatientFileMetadataParseHelpers.optionalString(
          map['display_name'],
        ) ??
        PatientFileMetadataParseHelpers.optionalString(map['file_name']) ??
        PatientFileMetadataParseHelpers.optionalString(map['document_type']) ??
        '';

    final statusValue = statusRaw ??
        PatientFileMetadataParseHelpers.optionalString(map['status']) ??
        'active';

    return PatientFileMetadataDto(
      id: id,
      tenantId: tenantId,
      patientId: patientId,
      createdByUserId: _resolveCreatedByUserId(map),
      fileKind: PatientFileMetadataParseHelpers.optionalString(
            map['file_kind'],
          ) ??
          (isGeneratedPdf ? 'generated_pdf' : 'patient_upload'),
      clinicalContext: PatientFileMetadataParseHelpers.requireString(
        map,
        'clinical_context',
      ),
      encounterId: PatientFileMetadataParseHelpers.optionalString(
            map['encounter_id'],
          ) ??
          _encounterIdFromPdfSource(map),
      appointmentId:
          PatientFileMetadataParseHelpers.optionalString(map['appointment_id']),
      physiotherapySessionId: PatientFileMetadataParseHelpers.optionalString(
        map['physiotherapy_session_id'],
      ),
      displayName: displayName,
      originalFileName: PatientFileMetadataParseHelpers.optionalString(
            map['original_file_name'],
          ) ??
          PatientFileMetadataParseHelpers.optionalString(map['file_name']),
      mimeType: PatientFileMetadataParseHelpers.optionalString(map['mime_type']),
      fileSizeBytes: sizeBytes ??
          PatientFileMetadataParseHelpers.optionalInt(map['file_size_bytes']) ??
          PatientFileMetadataParseHelpers.optionalInt(map['size_bytes']),
      storageBucket: PatientFileMetadataParseHelpers.optionalString(
            map['storage_bucket'],
          ) ??
          'patient-files-private',
      storagePath: storagePath,
      checksum: PatientFileMetadataParseHelpers.optionalString(map['checksum']),
      status: statusValue,
      visibilityScope: PatientFileMetadataParseHelpers.optionalString(
            map['visibility_scope'],
          ) ??
          (isGeneratedPdf ? 'doctor_admin' : 'clinic_operations'),
      metadata: metadata ??
          PatientFileMetadataSanitizer.sanitize(
            PatientFileMetadataParseHelpers.coerceMetadataMap(map['metadata']),
          ),
      createdAt: PatientFileMetadataParseHelpers.requireDateTime(
        map['created_at'],
      ),
      updatedAt: PatientFileMetadataParseHelpers.optionalDateTime(
            map['updated_at'],
          ) ??
          PatientFileMetadataParseHelpers.optionalDateTime(map['created_at']),
      deletedAt:
          PatientFileMetadataParseHelpers.optionalDateTime(map['deleted_at']),
      isGeneratedPdf: isGeneratedPdf,
    );
  }

  static String? _resolveCreatedByUserId(Map<String, dynamic> map) {
    return PatientFileMetadataParseHelpers.optionalString(
          map['created_by_user_id'],
        ) ??
        PatientFileMetadataParseHelpers.optionalString(map['created_by']);
  }

  static void _mergePdfSourceMetadata(
    Map<String, dynamic> map,
    Map<String, Object?> meta,
  ) {
    final docType =
        PatientFileMetadataParseHelpers.optionalString(map['document_type']);
    if (docType != null) {
      meta[PatientFileMetadataExtraKeys.documentType] = docType;
    }
    final module =
        PatientFileMetadataParseHelpers.optionalString(map['source_module']);
    if (module != null) {
      meta[PatientFileMetadataExtraKeys.sourceModule] = module;
    }
    final recordId =
        PatientFileMetadataParseHelpers.optionalString(map['source_record_id']);
    if (recordId != null) {
      meta[PatientFileMetadataExtraKeys.sourceRecordId] = recordId;
    }
  }

  static String? _encounterIdFromPdfSource(Map<String, dynamic> map) {
    final module =
        PatientFileMetadataParseHelpers.optionalString(map['source_module']);
    if (module == 'clinical_encounter') {
      return PatientFileMetadataParseHelpers.optionalString(
        map['source_record_id'],
      );
    }
    return null;
  }
}
