import '../../../core/data/stub_module_availability.dart';
import 'clinical_role_summary_repository_provider.dart';

/// Asistan / FTR güvenli klinik özet — mock veya hazır remote oturum.
abstract final class ClinicalSummaryModuleAvailability {
  static bool get assistantOperational => StubModuleAvailability.isOperational(
        remoteReady: ClinicalRoleSummaryRepositoryProvider
            .usesRemoteAssistantClinicalSummaries,
      );

  static bool get physiotherapistOperational =>
      StubModuleAvailability.isOperational(
        remoteReady: ClinicalRoleSummaryRepositoryProvider
            .usesRemotePhysiotherapistClinicalSummaries,
      );
}
