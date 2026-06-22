import 'patient_file_metadata_enums.dart';

/// Hasta dosyası / PDF — storage metadata (içerik taşımaz).
///
/// Legacy UI: `lib/features/files/models/patient_file.dart`.
class PatientFileMetadata {
  final String id;
  final String tenantId;
  final String patientId;
  final String? createdByUserId;
  final PatientFileKind fileKind;
  final PatientFileClinicalContext clinicalContext;
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
  final PatientFileStatus status;
  final PatientFileVisibilityScope visibilityScope;
  final Map<String, Object?> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isGeneratedPdf;

  const PatientFileMetadata({
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

  bool get isActive =>
      status == PatientFileStatus.active && deletedAt == null;
}
