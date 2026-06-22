import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_clinical_data.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_treatment_approach.dart';

ClinicalEncounter _encounter({
  String orthosisNotes = 'Dizlik',
  ClinicalTreatmentApproach? treatmentApproach =
      ClinicalTreatmentApproach.conservative,
}) {
  return ClinicalEncounter(
    id: 'ce1',
    patientId: 'p1',
    patientName: 'Test',
    createdAt: DateTime(2026, 5, 20),
    updatedAt: DateTime(2026, 5, 20),
    doctorName: 'Dr',
    status: ClinicalEncounterStatus.taslak,
    visitType: ClinicalVisitType.ilkMuayene,
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
    preliminaryDiagnosis: '',
    finalDiagnosis: '',
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.diger,
    icdCode: '',
    planTitle: '',
    conservativeTreatment: '',
    medicationNotes: '',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: false,
    exerciseRecommendation: '',
    imagingRequest: '',
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: 'gizli',
    orthosisNotes: orthosisNotes,
    treatmentApproach: treatmentApproach,
  );
}

void main() {
  group('ClinicalEncounterClinicalData plan extensions', () {
    test('toMap includes orthosisNotes and treatmentApproach', () {
      final map = ClinicalEncounterClinicalData.toMap(_encounter());
      final plan = map['plan'] as Map<String, dynamic>;
      expect(plan['orthosisNotes'], 'Dizlik');
      expect(plan['treatmentApproach'], 'conservative');
      expect(map.toString().contains('gizli'), isFalse);
    });

    test('fromMap legacy record without new keys defaults safely', () {
      final fields = ClinicalEncounterClinicalData.fromMap({
        'schemaVersion': 1,
        'plan': {
          'planTitle': 'Plan',
        },
      });
      expect(fields.orthosisNotes, '');
      expect(fields.treatmentApproach, isNull);
    });

    test('unknown treatmentApproach falls back to null', () {
      final fields = ClinicalEncounterClinicalData.fromMap({
        'plan': {'treatmentApproach': 'invalid_value'},
      });
      expect(fields.treatmentApproach, isNull);
    });

    test('round trip surgical approach', () {
      final original = _encounter(
        orthosisNotes: 'Atel',
        treatmentApproach: ClinicalTreatmentApproach.surgical,
      );
      final fields = ClinicalEncounterClinicalData.fromMap(
        ClinicalEncounterClinicalData.toMap(original),
      );
      expect(fields.orthosisNotes, 'Atel');
      expect(fields.treatmentApproach, ClinicalTreatmentApproach.surgical);
    });
  });

  group('ClinicalTreatmentApproach', () {
    test('labels are Turkish', () {
      expect(ClinicalTreatmentApproach.conservative.label, 'Konservatif');
      expect(ClinicalTreatmentApproach.surgical.label, 'Cerrahi');
      expect(ClinicalTreatmentApproach.combined.label, 'Kombine');
      expect(ClinicalTreatmentApproach.observation.label, 'İzlem');
    });
  });
}
