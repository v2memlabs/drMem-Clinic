import '../models/physiotherapist_clinical_summary.dart';
import 'mock_clinical_encounters.dart';
import 'mock_physiotherapist_clinical_summary_mapper.dart';
import 'physiotherapist_clinical_summary_repository.dart';

/// Mock backend — allowlist FTR özet; full [ClinicalEncounter] UI'ya verilmez.
class MockPhysiotherapistClinicalSummaryRepository
    implements PhysiotherapistClinicalSummaryRepository {
  const MockPhysiotherapistClinicalSummaryRepository();

  @override
  Future<List<PhysiotherapistClinicalSummary>>
      listPhysiotherapistClinicalSummaries({
    String? patientId,
  }) async {
    final trimmedPatientId = patientId?.trim() ?? '';
    final encounters = trimmedPatientId.isNotEmpty
        ? mockClinicalEncounters.where((e) => e.patientId == trimmedPatientId)
        : mockClinicalEncounters;
    return encounters
        .map(MockPhysiotherapistClinicalSummaryMapper.fromEncounter)
        .toList();
  }

  @override
  Future<PhysiotherapistClinicalSummary?> getPhysiotherapistClinicalSummary(
    String encounterId,
  ) async {
    final trimmed = encounterId.trim();
    for (final encounter in mockClinicalEncounters) {
      if (encounter.id == trimmed) {
        return MockPhysiotherapistClinicalSummaryMapper.fromEncounter(
            encounter);
      }
    }
    return null;
  }
}
