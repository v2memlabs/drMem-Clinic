import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_body_region_mapping.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_search_helper.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';

ClinicalEncounter _encounter({
  String patientName = 'Ayşe Yılmaz',
  String finalDiagnosis = 'Menisküs yırtığı',
  String preliminaryDiagnosis = '',
  String icdCode = 'M23.2',
  String icdTitle = 'Menisküs',
  String planTitle = 'Konservatif',
  String internalDoctorNote = 'Gizli not',
}) {
  return ClinicalEncounter(
    id: 'ce-1',
    patientId: 'p-1',
    patientName: patientName,
    createdAt: DateTime(2026, 5, 21),
    updatedAt: DateTime(2026, 5, 21),
    doctorName: 'Dr. Test',
    status: ClinicalEncounterStatus.tamamlandi,
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
    preliminaryDiagnosis: preliminaryDiagnosis,
    finalDiagnosis: finalDiagnosis,
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.dejeneratif,
    icdCode: icdCode,
    icdTitle: icdTitle,
    planTitle: planTitle,
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
    internalDoctorNote: internalDoctorNote,
  );
}

void main() {
  group('ClinicalEncounterSearchHelper', () {
    final source = [
      _encounter(),
      _encounter(
        patientName: 'Mehmet Demir',
        finalDiagnosis: 'Rotator cuff',
        icdCode: 'M75.1',
        icdTitle: 'Rotator cuff sendromu',
      ),
    ];

    test('empty query returns all', () {
      expect(ClinicalEncounterSearchHelper.filter(source, ''), source);
      expect(ClinicalEncounterSearchHelper.filter(source, '   '), source);
    });

    test('matches patientName', () {
      final result = ClinicalEncounterSearchHelper.filter(source, 'ayşe');
      expect(result, hasLength(1));
      expect(result.first.patientName, 'Ayşe Yılmaz');
    });

    test('matches diagnosis and icd fields', () {
      expect(
        ClinicalEncounterSearchHelper.filter(source, 'menisküs'),
        hasLength(1),
      );
      expect(
        ClinicalEncounterSearchHelper.filter(source, 'm23.2'),
        hasLength(1),
      );
      expect(
        ClinicalEncounterSearchHelper.filter(source, 'rotator'),
        hasLength(1),
      );
    });

    test('does not search internalDoctorNote', () {
      expect(
        ClinicalEncounterSearchHelper.filter(source, 'gizli'),
        isEmpty,
      );
    });
  });
}
