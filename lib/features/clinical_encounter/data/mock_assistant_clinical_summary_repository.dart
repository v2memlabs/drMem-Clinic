import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_repository.dart';
import 'mock_assistant_clinical_summary_mapper.dart';
import 'mock_clinical_encounters.dart';

/// Mock backend — allowlist özet; full [ClinicalEncounter] UI'ya verilmez.
///
/// Veri yalnızca data katmanında async mock adapter üzerinden okunur;
/// sync [ClinicalEncounterRepository.instance] kullanılmaz.
class MockAssistantClinicalSummaryRepository
    implements AssistantClinicalSummaryRepository {
  const MockAssistantClinicalSummaryRepository();

  @override
  Future<List<AssistantClinicalSummary>> listAssistantClinicalSummaries({
    String? patientId,
  }) async {
    final trimmedPatientId = patientId?.trim() ?? '';
    final encounters = trimmedPatientId.isNotEmpty
        ? mockClinicalEncounters.where((e) => e.patientId == trimmedPatientId)
        : mockClinicalEncounters;
    return encounters
        .map(MockAssistantClinicalSummaryMapper.fromEncounter)
        .toList();
  }

  @override
  Future<AssistantClinicalSummary?> getAssistantClinicalSummary(
    String encounterId,
  ) async {
    final trimmed = encounterId.trim();
    for (final encounter in mockClinicalEncounters) {
      if (encounter.id == trimmed) {
        return MockAssistantClinicalSummaryMapper.fromEncounter(encounter);
      }
    }
    return null;
  }
}
