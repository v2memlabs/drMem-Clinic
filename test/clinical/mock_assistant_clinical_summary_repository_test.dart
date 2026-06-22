import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/mock_assistant_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/assistant_clinical_summary.dart';

void main() {
  test('returns AssistantClinicalSummary not ClinicalEncounter', () async {
    const repo = MockAssistantClinicalSummaryRepository();
    final list = await repo.listAssistantClinicalSummaries();
    expect(list, isNotEmpty);
    expect(list.first, isA<AssistantClinicalSummary>());
  });

  test('getById returns null for unknown id', () async {
    const repo = MockAssistantClinicalSummaryRepository();
    final item = await repo.getAssistantClinicalSummary('missing-id');
    expect(item, isNull);
  });

  test('getById returns summary for mock encounter id', () async {
    const repo = MockAssistantClinicalSummaryRepository();
    final item = await repo.getAssistantClinicalSummary('ce1');
    expect(item?.encounterId, 'ce1');
    expect(item?.patientDisplayName, isNotEmpty);
  });
}
