import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_list_filters.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/assistant_clinical_summary.dart';

AssistantClinicalSummary _sample({
  String name = 'Ayşe Yılmaz',
  String? diagnosisSummary,
}) {
  return AssistantClinicalSummary(
    encounterId: 'ce-1',
    tenantId: 'tenant-1',
    patientId: 'p-1',
    patientDisplayName: name,
    encounterDate: DateTime(2026, 5, 21),
    diagnosisSummary: diagnosisSummary,
  );
}

void main() {
  test('search matches patient display name', () {
    final filtered = AssistantClinicalSummaryListFilters.applySearch(
      [_sample(), _sample(name: 'Mehmet Kaya')],
      'mehmet',
    );
    expect(filtered, hasLength(1));
    expect(filtered.first.patientDisplayName, 'Mehmet Kaya');
  });

  test('search does not use internalDoctorNote-like fields', () {
    final filtered = AssistantClinicalSummaryListFilters.applySearch(
      [_sample(diagnosisSummary: 'Diz ağrısı')],
      'gizli',
    );
    expect(filtered, isEmpty);
  });
}
