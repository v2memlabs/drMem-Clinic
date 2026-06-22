import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/assistant_clinical_summary_list_state_messages.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/physiotherapist_clinical_summary_list_state_messages.dart';

void main() {
  group('AssistantClinicalSummaryListStateMessages', () {
    test('empty source uses generic clinical empty copy', () {
      expect(
        AssistantClinicalSummaryListStateMessages.emptyDescription(
          search: '',
          hasPatientFilter: false,
          emptySourceList: true,
        ),
        'Görüntülenebilecek klinik özet bulunamadı.',
      );
    });

    test('search empty uses search hint', () {
      expect(
        AssistantClinicalSummaryListStateMessages.emptyTitle(
          search: 'diz',
          hasPatientFilter: false,
          emptySourceList: false,
        ),
        AssistantClinicalSummaryListStateMessages.emptySearchTitle,
      );
    });
  });

  group('PhysiotherapistClinicalSummaryListStateMessages', () {
    test('region filter empty uses filter title', () {
      expect(
        PhysiotherapistClinicalSummaryListStateMessages.emptyTitle(
          search: '',
          hasPatientFilter: false,
          hasRegionFilter: true,
          hasStatusFilter: false,
          emptySourceList: false,
        ),
        PhysiotherapistClinicalSummaryListStateMessages.emptyFilterTitle,
      );
    });

    test('empty source uses FTR generic empty copy', () {
      expect(
        PhysiotherapistClinicalSummaryListStateMessages.emptyDescription(
          search: '',
          hasPatientFilter: false,
          hasRegionFilter: false,
          hasStatusFilter: false,
          emptySourceList: true,
        ),
        'Görüntülenebilecek FTR klinik özeti bulunamadı.',
      );
    });
  });
}
