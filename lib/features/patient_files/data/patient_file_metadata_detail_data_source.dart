import '../models/patient_file_metadata.dart';
import 'patient_file_metadata_list_user_messages.dart';
import 'patient_file_metadata_repository_failure.dart';
import 'patient_file_metadata_repository_provider.dart';

class PatientFileMetadataDetailLoadResult {
  final PatientFileMetadata? file;
  final String? errorMessage;

  const PatientFileMetadataDetailLoadResult._({
    this.file,
    this.errorMessage,
  });

  factory PatientFileMetadataDetailLoadResult.success(
    PatientFileMetadata file,
  ) {
    return PatientFileMetadataDetailLoadResult._(file: file);
  }

  factory PatientFileMetadataDetailLoadResult.failure(String message) {
    return PatientFileMetadataDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class PatientFileMetadataDetailDataSource {
  static Future<PatientFileMetadataDetailLoadResult> load(String fileId) async {
    final id = fileId.trim();
    if (id.isEmpty) {
      return PatientFileMetadataDetailLoadResult.failure(
        PatientFileMetadataListUserMessages.errorDescription,
      );
    }

    try {
      final file =
          await PatientFileMetadataRepositoryProvider.repository
              .getPatientFileMetadata(id);
      if (file == null) {
        return PatientFileMetadataDetailLoadResult.failure(
          'Dosya kaydı bulunamadı.',
        );
      }
      return PatientFileMetadataDetailLoadResult.success(file);
    } on PatientFileMetadataRepositoryException catch (e) {
      return PatientFileMetadataDetailLoadResult.failure(
        PatientFileMetadataListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PatientFileMetadataDetailLoadResult.failure(
        PatientFileMetadataListUserMessages.errorDescription,
      );
    }
  }
}
