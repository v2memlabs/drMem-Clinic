import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/mock_physiotherapist_clinical_summary_repository.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/physiotherapist_clinical_summary.dart';

void main() {
  test('returns PhysiotherapistClinicalSummary not ClinicalEncounter', () async {
    const repo = MockPhysiotherapistClinicalSummaryRepository();
    final list = await repo.listPhysiotherapistClinicalSummaries();
    expect(list, isNotEmpty);
    expect(list.first, isA<PhysiotherapistClinicalSummary>());
  });

  test('getById returns summary for mock encounter id', () async {
    const repo = MockPhysiotherapistClinicalSummaryRepository();
    final item = await repo.getPhysiotherapistClinicalSummary('ce1');
    expect(item?.encounterId, 'ce1');
    expect(item?.bodyRegion, isNotNull);
  });
}
