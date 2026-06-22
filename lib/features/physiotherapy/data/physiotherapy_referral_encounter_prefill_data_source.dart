import '../../../core/data/repository_registry.dart';
import '../../clinical_encounter/models/clinical_encounter.dart';
import 'physiotherapy_referral_user_messages.dart';

class PhysiotherapyReferralEncounterPrefillResult {
  final ClinicalEncounter? encounter;
  final String? errorMessage;
  final bool isLoading;

  const PhysiotherapyReferralEncounterPrefillResult._({
    this.encounter,
    this.errorMessage,
    this.isLoading = false,
  });

  factory PhysiotherapyReferralEncounterPrefillResult.loading() {
    return const PhysiotherapyReferralEncounterPrefillResult._(isLoading: true);
  }

  factory PhysiotherapyReferralEncounterPrefillResult.success(
    ClinicalEncounter encounter,
  ) {
    return PhysiotherapyReferralEncounterPrefillResult._(encounter: encounter);
  }

  factory PhysiotherapyReferralEncounterPrefillResult.notFound() {
    return const PhysiotherapyReferralEncounterPrefillResult._();
  }

  factory PhysiotherapyReferralEncounterPrefillResult.failure(String message) {
    return PhysiotherapyReferralEncounterPrefillResult._(errorMessage: message);
  }
}

/// Muayene kaydından güvenli prefill — async remote/mock encounter.
abstract final class PhysiotherapyReferralEncounterPrefillDataSource {
  static Future<PhysiotherapyReferralEncounterPrefillResult> loadEncounter(
    String encounterId,
  ) async {
    final id = encounterId.trim();
    if (id.isEmpty) {
      return PhysiotherapyReferralEncounterPrefillResult.notFound();
    }

    try {
      final encounter =
          await RepositoryRegistry.clinicalEncountersAsync.getById(id);
      if (encounter == null) {
        return PhysiotherapyReferralEncounterPrefillResult.notFound();
      }
      return PhysiotherapyReferralEncounterPrefillResult.success(encounter);
    } on Object catch (_) {
      return PhysiotherapyReferralEncounterPrefillResult.failure(
        PhysiotherapyReferralFormUserMessages.encounterLoadFailure,
      );
    }
  }
}
