import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_detail_display.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_display.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/physiotherapist_clinical_summary.dart';

void main() {
  final summary = PhysiotherapistClinicalSummary(
    encounterId: 'ce-1',
    tenantId: 'tenant-1',
    patientId: 'p-1',
    patientDisplayName: 'Test Hasta',
    encounterDate: DateTime(2026, 5, 21),
    bodyRegion: 'knee',
    side: 'right',
    visitType: 'follow_up',
    status: 'completed',
    physiotherapyReferral: true,
    exerciseRecommendationShort: 'Quadriceps',
    diagnosisSummary: 'Diz ağrısı',
    treatmentPlanSummary: 'FTR planı',
  );

  test('detail rows exclude technical ids', () {
    final patientRows =
        PhysiotherapistClinicalSummaryDetailDisplay.patientRows(summary);
    final rehabRows =
        PhysiotherapistClinicalSummaryDetailDisplay.rehabRows(summary);
    final all = [...patientRows, ...rehabRows];
    final labels = all.map((r) => '${r.label}').join(' ');
    final values = all.map((r) => '${r.value}').join(' ');

    expect(labels.contains('tenant'), isFalse);
    expect(values.contains('ce-1'), isFalse);
    expect(values.contains('Quadriceps'), isTrue);
  });

  test('list chips use region label not raw db only', () {
    final chips = PhysiotherapistClinicalSummaryDisplay.listChips(summary);
    expect(chips.first, contains('Diz'));
  });
}
