import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_list_display.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';

ClinicalEncounter _base({
  String finalDiagnosis = '',
  String preliminaryDiagnosis = '',
  String icdCode = '',
  String planTitle = '',
}) {
  return ClinicalEncounter(
    id: 'e1',
    patientId: 'p1',
    patientName: 'Test Hasta',
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
    preliminaryDiagnosis: preliminaryDiagnosis,
    finalDiagnosis: finalDiagnosis,
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.diger,
    icdCode: icdCode,
    planTitle: planTitle,
    conservativeTreatment: '',
    medicationNotes: '',
    injectionOrProcedurePlan: '',
    physiotherapyReferral: false,
    exerciseRecommendation: '',
    imagingRequest: '',
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: 'gizli not',
  );
}

void main() {
  group('ClinicalEncounterListDisplay', () {
    test('cardMetaLine remote empty diagnosis returns null', () {
      expect(
        ClinicalEncounterListDisplay.cardMetaLine(_base(), usesRemote: true),
        isNull,
      );
    });

    test('cardMetaLine mock empty diagnosis shows placeholder', () {
      expect(
        ClinicalEncounterListDisplay.cardMetaLine(_base(), usesRemote: false),
        'Tanı belirtilmedi',
      );
    });

    test('cardMetaLine shows final diagnosis when present', () {
      expect(
        ClinicalEncounterListDisplay.cardMetaLine(
          _base(finalDiagnosis: 'Menisküs yırtığı'),
          usesRemote: true,
        ),
        'Kesin tanı: Menisküs yırtığı',
      );
    });

    test('listDetailLine combines visit type and diagnosis without protocol', () {
      expect(
        ClinicalEncounterListDisplay.listDetailLine(
          _base(finalDiagnosis: 'Menisküs yırtığı'),
          usesRemote: true,
        ),
        'İlk Muayene · Kesin tanı: Menisküs yırtığı',
      );
      expect(
        ClinicalEncounterListDisplay.listDetailLine(
          _base(preliminaryDiagnosis: 'ACL şüphesi'),
          usesRemote: true,
        ),
        'İlk Muayene · Ön tanı: ACL şüphesi',
      );
    });

    test('cardContextLine null without icd', () {
      expect(ClinicalEncounterListDisplay.cardContextLine(_base()), isNull);
    });

    test('internalDoctorNote never exposed via display helpers', () {
      final encounter = _base(icdCode: 'M23.2');
      expect(encounter.internalDoctorNote, isNotEmpty);
      expect(
        ClinicalEncounterListDisplay.cardMetaLine(encounter, usesRemote: true),
        isNull,
      );
      expect(
        ClinicalEncounterListDisplay.treatmentContextLine(encounter),
        isNull,
      );
    });
  });
}
