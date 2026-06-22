import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_detail_display.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_display.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/assistant_clinical_summary.dart';

void main() {
  final summary = AssistantClinicalSummary(
    encounterId: 'ce-1',
    tenantId: 'tenant-1',
    patientId: 'p-1',
    patientDisplayName: 'Test Hasta',
    encounterDate: DateTime(2026, 5, 21),
    visitType: 'follow_up',
    status: 'completed',
    diagnosisSummary: 'Diz kontrol',
    hasPhysiotherapyReferral: true,
  );

  test('detail rows exclude technical ids', () {
    final rows = AssistantClinicalSummaryDetailDisplay.detailRows(summary);
    final labels = rows.map((r) => '${r.label}').join(' ');
    final values = rows.map((r) => '${r.value}').join(' ');

    expect(labels.contains('tenant'), isFalse);
    expect(values.contains('ce-1'), isFalse);
    expect(values.contains('tenant-1'), isFalse);
    expect(values.contains('Diz kontrol'), isTrue);
  });

  test('list subtitle uses diagnosis summary', () {
    expect(
      AssistantClinicalSummaryDisplay.listSubtitle(summary),
      'Diz kontrol',
    );
  });
}
