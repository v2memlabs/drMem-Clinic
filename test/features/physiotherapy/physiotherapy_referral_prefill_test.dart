import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/physiotherapy/data/physiotherapy_referral_encounter_prefill_data_source.dart';
import 'package:v2mem_clinic/features/physiotherapy/physiotherapy_referral_prefill.dart';

ClinicalEncounter _base({
  String finalDiagnosis = 'Kesin tanı',
  bool physiotherapyReferral = true,
  String exerciseRecommendation = 'Quadriceps set',
  String internalDoctorNote = 'Gizli not',
}) {
  return ClinicalEncounter(
    id: 'ce-test',
    patientId: 'p1',
    patientName: 'Test Hasta',
    createdAt: DateTime(2026, 5, 20),
    updatedAt: DateTime(2026, 5, 20),
    doctorName: 'Dr. Test',
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
    finalDiagnosis: finalDiagnosis,
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.diger,
    icdCode: '',
    planTitle: 'Plan',
    conservativeTreatment: 'Konservatif',
    medicationNotes: '',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: physiotherapyReferral,
    exerciseRecommendation: exerciseRecommendation,
    imagingRequest: '',
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: internalDoctorNote,
  );
}

void main() {
  test('prefill data source exposes async load contract', () {
    expect(
      PhysiotherapyReferralEncounterPrefillDataSource.loadEncounter,
      isNotNull,
    );
  });

  test('prefill helper excludes internal doctor note from diagnosis summary', () {
    final encounter = _base();

    expect(
      PhysiotherapyReferralPrefill.diagnosisSummary(encounter),
      'Kesin tanı',
    );
    expect(
      PhysiotherapyReferralPrefill.diagnosisSummary(encounter),
      isNot(contains('Gizli not')),
    );
  });

  test('prefill treatment goal can include exercise recommendation', () {
    final encounter = _base();

    expect(
      PhysiotherapyReferralPrefill.treatmentGoal(encounter),
      contains('Quadriceps set'),
    );
  });
}
