import '../../../core/data/stub_module_availability.dart';
import 'patient_tag_repository_provider.dart';

/// Hasta etiket modülü — mock veya hazır remote oturum.
abstract final class PatientTagModuleAvailability {
  static bool get isOperational => StubModuleAvailability.isOperational(
        remoteReady: PatientTagRepositoryProvider.usesRemote,
      );
}
