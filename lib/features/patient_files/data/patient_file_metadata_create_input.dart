import '../models/patient_file_metadata_enums.dart';
import 'patient_file_metadata_sanitizer.dart';
import 'patient_file_storage_path_builder.dart';

/// Yeni dosya metadata kaydı — binary/upload/signed URL yok; tenant UI'dan gelmez.
class PatientFileMetadataCreateInput {
  final String patientId;
  final PatientFileKind fileKind;
  final PatientFileClinicalContext clinicalContext;
  final String displayName;
  final String storageBucket;
  final String storagePath;
  final String? encounterId;
  final String? appointmentId;
  final String? physiotherapySessionId;
  final String? originalFileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final String? checksum;
  final PatientFileVisibilityScope visibilityScope;
  final Map<String, Object?> metadata;

  PatientFileMetadataCreateInput({
    required this.patientId,
    required this.fileKind,
    required this.clinicalContext,
    required this.displayName,
    required this.storagePath,
    this.storageBucket = PatientFileStoragePathBuilder.defaultBucket,
    this.encounterId,
    this.appointmentId,
    this.physiotherapySessionId,
    this.originalFileName,
    this.mimeType,
    this.fileSizeBytes,
    this.checksum,
    this.visibilityScope = PatientFileVisibilityScope.clinicOperations,
    Map<String, Object?>? metadata,
  })  : metadata = PatientFileMetadataSanitizer.sanitize(metadata ?? {});

  void validate() {
    if (patientId.trim().isEmpty ||
        displayName.trim().isEmpty ||
        storagePath.trim().isEmpty ||
        storageBucket.trim().isEmpty) {
      throw ArgumentError('PatientFileMetadataCreateInput: required fields empty');
    }
  }
}
