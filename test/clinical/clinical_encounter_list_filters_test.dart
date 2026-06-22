import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_list_filters.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';

ClinicalEncounter _encounter({
  required String id,
  ClinicalVisitType visit = ClinicalVisitType.ilkMuayene,
  ClinicalEncounterStatus status = ClinicalEncounterStatus.taslak,
  ClinicalBodyRegion region = ClinicalBodyRegion.diz,
  String patientName = 'Ali',
  String chiefComplaint = '',
}) {
  return ClinicalEncounter(
    id: id,
    patientId: 'p1',
    patientName: patientName,
    createdAt: DateTime(2026, 5, 20),
    updatedAt: DateTime(2026, 5, 20),
    doctorName: 'Dr',
    status: status,
    visitType: visit,
    bodyRegion: region,
    side: ClinicalSide.sag,
    chiefComplaint: chiefComplaint,
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
    internalDoctorNote: '',
  );
}

void main() {
  final items = [
    _encounter(id: '1', visit: ClinicalVisitType.kontrol),
    _encounter(
      id: '2',
      status: ClinicalEncounterStatus.tamamlandi,
      region: ClinicalBodyRegion.omuz,
      chiefComplaint: 'Omuz ağrısı',
    ),
  ];

  group('ClinicalEncounterListFilters', () {
    test('applyVisitType filters', () {
      final out = ClinicalEncounterListFilters.applyVisitType(
        items,
        ClinicalVisitType.kontrol,
      );
      expect(out, hasLength(1));
      expect(out.first.id, '1');
    });

    test('applyMockSearch matches chief complaint', () {
      final out = ClinicalEncounterListFilters.applyMockSearch(
        items,
        'omuz',
      );
      expect(out, hasLength(1));
      expect(out.first.id, '2');
    });
  });
}
