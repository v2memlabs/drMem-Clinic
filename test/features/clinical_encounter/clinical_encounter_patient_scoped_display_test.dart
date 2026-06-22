import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_patient_scoped_display.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_treatment_approach.dart';

ClinicalEncounter _encounter({
  ClinicalEncounterStatus status = ClinicalEncounterStatus.tamamlandi,
  String preliminary = '',
  String finalDx = 'Sağ diz medial menisküs dejeneratif yırtık',
}) {
  return ClinicalEncounter(
    id: 'ce-test',
    patientId: 'p1',
    patientName: 'Ahmet Yılmaz',
    createdAt: DateTime(2026, 5, 29),
    updatedAt: DateTime(2026, 5, 29),
    doctorName: 'Dr. Mehmet Yalçınozan',
    status: status,
    visitType: ClinicalVisitType.ilkMuayene,
    bodyRegion: ClinicalBodyRegion.diz,
    side: ClinicalSide.sag,
    chiefComplaint: 'Ağrı',
    complaintDuration: '3 ay',
    traumaHistory: false,
    painLocation: '',
    painCharacter: '',
    vasScore: 3,
    nightPain: false,
    activityRelation: '',
    previousTreatments: '',
    medications: '',
    allergies: '',
    comorbidities: '',
    previousSurgeries: '',
    generalNotes: '',
    sportsSectionEnabled: false,
    sportBranch: '',
    amateurOrProfessional: '',
    trainingFrequency: '',
    patientExpectation: '',
    returnToSportGoal: '',
    sportsRelated: false,
    returnToSportPlan: '',
    inspection: '',
    palpation: '',
    rangeOfMotion: '',
    muscleStrength: '',
    stabilityTests: '',
    specialTests: '',
    neurovascularStatus: '',
    comparisonWithOtherSide: '',
    clinicalImpression: '',
    imagingSummary: '',
    imagingDoctorComment: '',
    attachedFileNote: '',
    preliminaryDiagnosis: preliminary,
    finalDiagnosis: finalDx,
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.dejeneratif,
    icdCode: 'M23.2',
    icdTitle: 'İç diz (menisküs) bozukluğu',
    planTitle: 'Konservatif diz tedavisi',
    conservativeTreatment: 'Egzersiz programı',
    medicationNotes: '',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: false,
    exerciseRecommendation: '',
    imagingRequest: '',
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: 'Gizli not',
    orthosisNotes: '',
    treatmentApproach: ClinicalTreatmentApproach.conservative,
  );
}

void main() {
  test('title uses visit type and long date without patient name', () {
    final title = ClinicalEncounterPatientScopedDisplay.titleLine(_encounter());
    expect(title, contains('İlk Muayene'));
    expect(title, contains('29 Mayıs 2026'));
    expect(title, isNot(contains('Ahmet')));
  });

  test('diagnosis subtitle prefers final diagnosis', () {
    final subtitle =
        ClinicalEncounterPatientScopedDisplay.diagnosisSubtitle(_encounter());
    expect(subtitle, startsWith('Tanı:'));
    expect(subtitle, contains('menisküs'));
  });

  test('diagnosis subtitle uses preliminary when final empty', () {
    final subtitle = ClinicalEncounterPatientScopedDisplay.diagnosisSubtitle(
      _encounter(finalDx: '', preliminary: 'Menisküs yaralanması'),
    );
    expect(subtitle, 'Ön tanı: Menisküs yaralanması');
  });

  test('meta lines include plan and doctor icd without internal note', () {
    final meta = ClinicalEncounterPatientScopedDisplay.metaLines(
      _encounter(),
      usesRemote: false,
    );
    expect(meta.length, lessThanOrEqualTo(2));
    expect(meta.any((l) => l.contains('Egzersiz programı')), isTrue);
    expect(meta.any((l) => l.contains('ICD')), isTrue);
    expect(meta.any((l) => l.contains('Gizli')), isFalse);
  });

  test('status trailing is plain label', () {
    expect(
      ClinicalEncounterPatientScopedDisplay.statusTrailing(
        _encounter(status: ClinicalEncounterStatus.kontrolPlanlandi),
      ),
      'Kontrol Planlandı',
    );
  });
}
