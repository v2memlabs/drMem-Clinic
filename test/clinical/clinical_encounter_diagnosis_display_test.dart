import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_diagnosis_display.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';

ClinicalEncounter _encounter({
  String preliminary = '',
  String finalDx = '',
  String differential = '',
  String icdCode = '',
  String icdTitle = '',
}) {
  return ClinicalEncounter(
    id: 'ce-dx',
    patientId: 'p1',
    patientName: 'Hasta',
    createdAt: DateTime(2026, 5, 20),
    updatedAt: DateTime(2026, 5, 20),
    doctorName: 'Dr.',
    status: ClinicalEncounterStatus.tamamlandi,
    visitType: ClinicalVisitType.kontrol,
    bodyRegion: ClinicalBodyRegion.diz,
    side: ClinicalSide.sag,
    chiefComplaint: '',
    complaintDuration: '',
    traumaHistory: false,
    painLocation: '',
    painCharacter: '',
    vasScore: 0,
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
    differentialDiagnosis: differential,
    diagnosisType: ClinicalDiagnosisType.dejeneratif,
    icdCode: icdCode,
    icdTitle: icdTitle,
    planTitle: '',
    conservativeTreatment: '',
    medicationNotes: '',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: false,
    exerciseRecommendation: '',
    imagingRequest: '',
    controlDate: null,
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: '',
    orthosisNotes: '',
    treatmentApproach: null,
  );
}

void main() {
  group('ClinicalEncounterDiagnosisDisplay', () {
    test('detailRows without final diagnosis keeps full order', () {
      final rows = ClinicalEncounterDiagnosisDisplay.detailRows(
        _encounter(
          preliminary: 'Ön',
          differential: 'Ayırıcı',
          finalDx: '',
        ),
      );

      expect(rows.map((r) => r.label).toList(), [
        'Ön tanı',
        'Ayırıcı tanı',
        'Kesin tanı',
        'Tanı tipi',
        'ICD-10 kodu',
      ]);
    });

    test('detailRows with final diagnosis shows only final and ICD-10', () {
      final rows = ClinicalEncounterDiagnosisDisplay.detailRows(
        _encounter(
          preliminary: 'Ön',
          differential: 'Ayırıcı',
          finalDx: 'Kesin tanı metni',
          icdCode: 'M17',
          icdTitle: 'Gonartroz',
        ),
      );

      expect(rows.map((r) => r.label).toList(), [
        'Kesin tanı',
        'ICD-10 kodu',
      ]);
      expect(rows.first.value, 'Kesin tanı metni');
      expect(rows.last.value, contains('M17'));
    });

    test('pdfRows with final diagnosis omits preliminary and differential', () {
      final rows = ClinicalEncounterDiagnosisDisplay.pdfRows(
        _encounter(
          preliminary: 'Ön',
          differential: 'Ayırıcı',
          finalDx: 'Kesin',
          icdCode: 'S83',
        ),
      );

      expect(rows.map((r) => r.label).toList(), [
        'Kesin tanı',
        'ICD-10 kodu',
      ]);
    });
  });
}
