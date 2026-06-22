import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_list_filter_labels.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';

void main() {
  test('short visit type labels differ from long labels for overflow cases', () {
    expect(
      ClinicalEncounterListFilterLabels.visitType(
        ClinicalVisitType.girisimOncesiDegerlendirme,
      ),
      isNot(ClinicalVisitType.girisimOncesiDegerlendirme.label),
    );
    expect(
      ClinicalEncounterListFilterLabels.visitType(
        ClinicalVisitType.girisimOncesiDegerlendirme,
      ),
      'Girişim Önc. Değ.',
    );
  });

  test('short status labels for long statuses', () {
    expect(
      ClinicalEncounterListFilterLabels.status(
        ClinicalEncounterStatus.fizyoterapiyeYonlendirildi,
      ),
      'FTR Yönlendirildi',
    );
    expect(
      ClinicalEncounterListFilterLabels.status(
        ClinicalEncounterStatus.ameliyatPlanlandi,
      ),
      'Ameliyat Planı',
    );
  });
}
