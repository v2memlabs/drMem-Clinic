import '../../files/data/mock_patient_files.dart';
import '../../files/models/patient_file.dart';
import '../models/patient_file_metadata.dart';
import '../models/patient_file_metadata_enums.dart';
import 'patient_file_metadata_create_input.dart';
import 'patient_file_storage_path_builder.dart';

/// Legacy [PatientFile] → [PatientFileMetadata] (mock backend).
abstract final class MockPatientFileMetadataMapper {
  static const String mockTenantId = 'mock-tenant';

  static PatientFileMetadata fromLegacyFile(PatientFile file) {
    final isPdf = file.fileType.contains('pdf');
    return PatientFileMetadata(
      id: file.id,
      tenantId: mockTenantId,
      patientId: file.patientId,
      fileKind: isPdf
          ? PatientFileKind.generatedPdf
          : PatientFileKind.patientUpload,
      clinicalContext: PatientFileClinicalContext.patient,
      displayName: file.fileName,
      originalFileName: file.fileName,
      mimeType: file.fileType,
      storageBucket: PatientFileStoragePathBuilder.defaultBucket,
      storagePath: _internalStoragePath(file),
      status: PatientFileStatus.active,
      visibilityScope: PatientFileVisibilityScope.clinicOperations,
      metadata: {
        if (file.description != null && file.description!.trim().isNotEmpty)
          'description': file.description!.trim(),
        if (file.uploadedBy.trim().isNotEmpty)
          'uploaded_by_display': file.uploadedBy.trim(),
      },
      createdAt: file.uploadedAt,
      isGeneratedPdf: isPdf,
    );
  }

  static PatientFile toLegacyFile(PatientFileMetadataCreateInput input) {
    return PatientFile(
      id: 'mock-file-${DateTime.now().millisecondsSinceEpoch}',
      patientId: input.patientId,
      patientName: 'Hasta',
      fileName: input.displayName,
      fileType: input.mimeType ?? 'application/octet-stream',
      uploadedAt: DateTime.now(),
      uploadedBy: 'Mock',
      description: input.metadata['description']?.toString() ?? '',
    );
  }

  static String _internalStoragePath(PatientFile file) {
    return 'mock/${file.patientId}/${file.id}/${file.fileName}';
  }
}
