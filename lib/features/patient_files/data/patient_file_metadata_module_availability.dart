import '../../../core/data/stub_module_availability.dart';
import 'patient_file_metadata_repository_provider.dart';

/// Hasta dosya metadata — mock veya hazır remote oturum.
abstract final class PatientFileMetadataModuleAvailability {
  static bool get isOperational => StubModuleAvailability.isOperational(
        remoteReady:
            PatientFileMetadataRepositoryProvider.usesRemotePatientFileMetadata,
      );
}
