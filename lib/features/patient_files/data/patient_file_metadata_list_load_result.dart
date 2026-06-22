import '../models/patient_file_metadata.dart';

/// Hasta dosya metadata listesi yükleme sonucu.
class PatientFileMetadataListLoadResult {
  final List<PatientFileMetadata> files;
  final String? errorMessage;
  final bool isNotConfigured;

  const PatientFileMetadataListLoadResult._({
    required this.files,
    this.errorMessage,
    this.isNotConfigured = false,
  });

  factory PatientFileMetadataListLoadResult.success(
    List<PatientFileMetadata> files,
  ) {
    return PatientFileMetadataListLoadResult._(files: files);
  }

  factory PatientFileMetadataListLoadResult.notConfigured() {
    return const PatientFileMetadataListLoadResult._(
      files: [],
      isNotConfigured: true,
    );
  }

  factory PatientFileMetadataListLoadResult.failure(String message) {
    return PatientFileMetadataListLoadResult._(
      files: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
