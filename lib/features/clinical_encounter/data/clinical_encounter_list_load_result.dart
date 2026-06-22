import '../models/clinical_encounter.dart';

/// Muayene listesi yükleme sonucu.
class ClinicalEncounterListLoadResult {
  final List<ClinicalEncounter> encounters;
  final String? errorMessage;

  const ClinicalEncounterListLoadResult._({
    required this.encounters,
    this.errorMessage,
  });

  factory ClinicalEncounterListLoadResult.success(
    List<ClinicalEncounter> encounters,
  ) {
    return ClinicalEncounterListLoadResult._(encounters: encounters);
  }

  factory ClinicalEncounterListLoadResult.failure(String message) {
    return ClinicalEncounterListLoadResult._(
      encounters: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
