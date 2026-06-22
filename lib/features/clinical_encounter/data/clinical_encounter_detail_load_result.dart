import '../models/clinical_encounter.dart';

/// Muayene detay yükleme sonucu.
class ClinicalEncounterDetailLoadResult {
  final ClinicalEncounter? encounter;
  final String? errorMessage;

  const ClinicalEncounterDetailLoadResult._({
    this.encounter,
    this.errorMessage,
  });

  factory ClinicalEncounterDetailLoadResult.success(ClinicalEncounter encounter) {
    return ClinicalEncounterDetailLoadResult._(encounter: encounter);
  }

  factory ClinicalEncounterDetailLoadResult.notFound() {
    return const ClinicalEncounterDetailLoadResult._();
  }

  factory ClinicalEncounterDetailLoadResult.failure(String message) {
    return ClinicalEncounterDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
