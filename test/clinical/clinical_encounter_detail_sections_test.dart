import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_detail_sections.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_treatment_approach.dart';

void main() {
  final encounter = ClinicalEncounter(
    id: 'ce1',
    protocolNumber: 'M-2026-00099',
    patientId: 'p1',
    patientName: 'Ahmet Yılmaz',
    createdAt: DateTime(2026, 5, 20),
    updatedAt: DateTime(2026, 5, 21),
    doctorName: 'Dr. Test',
    status: ClinicalEncounterStatus.tamamlandi,
    visitType: ClinicalVisitType.kontrol,
    bodyRegion: ClinicalBodyRegion.diz,
    side: ClinicalSide.sag,
    chiefComplaint: 'Ağrı',
    complaintDuration: '2 hafta',
    traumaHistory: false,
    painLocation: '',
    painCharacter: '',
    vasScore: 4,
    nightPain: false,
    activityRelation: '',
    previousTreatments: '',
    medications: 'İbuprofen',
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
    inspection: 'Normal',
    palpation: '',
    rangeOfMotion: '',
    muscleStrength: '',
    stabilityTests: '',
    specialTests: '',
    neurovascularStatus: '',
    comparisonWithOtherSide: '',
    clinicalImpression: 'İzlem',
    imagingSummary: 'MR normal',
    imagingDoctorComment: '',
    attachedFileNote: '',
    preliminaryDiagnosis: 'Ön tanı',
    finalDiagnosis: 'Kesin',
    differentialDiagnosis: '',
    diagnosisType: ClinicalDiagnosisType.dejeneratif,
    icdCode: 'M17',
    icdTitle: 'Gonartroz',
    planTitle: 'Plan A',
    conservativeTreatment: 'Egzersiz',
    medicationNotes: 'NSAID',
    injectionOrProcedurePlan: 'PRP',
    physiotherapyReferral: true,
    exerciseRecommendation: 'Quadriceps',
    imagingRequest: '',
    controlDate: DateTime(2026, 6, 1),
    surgeryRecommendation: '',
    patientInformationNote: '',
    warningNotes: '',
    internalDoctorNote: 'gizli',
    orthosisNotes: 'Dizlik',
    treatmentApproach: ClinicalTreatmentApproach.conservative,
  );

  group('ClinicalEncounterDetailSections', () {
    test('identity section shows protocol number', () {
      final rows = ClinicalEncounterDetailSections.identity(encounter);
      expect(
        rows.any(
          (r) => r.label == 'Protokol No' && r.value == 'M-2026-00099',
        ),
        isTrue,
      );
    });

    test('complaint section emphasizes chief complaint', () {
      final rows = ClinicalEncounterDetailSections.complaintStory(encounter);
      expect(rows.first.label, 'Ana Şikayet');
      expect(rows.first.emphasize, isTrue);
      expect(
        rows.any((r) => r.label == 'Kullandığı İlaçlar' && r.value == 'İbuprofen'),
        isTrue,
      );
    });

    test('treatment plan includes approach and orthosis', () {
      final rows = ClinicalEncounterDetailSections.treatmentPlan(encounter);
      expect(
        rows.any((r) => r.label == 'Tedavi Yaklaşımı' && r.value == 'Konservatif'),
        isTrue,
      );
      expect(
        rows.any((r) => r.label == 'Ortez / Atel / Destek' && r.value == 'Dizlik'),
        isTrue,
      );
    });

    test('section titles cover seven clinical blocks', () {
      expect(
        ClinicalEncounterDetailSections.examination(encounter).isNotEmpty,
        isTrue,
      );
      expect(
        ClinicalEncounterDetailSections.imaging(encounter).isNotEmpty,
        isTrue,
      );
      expect(
        ClinicalEncounterDetailSections.diagnosis(encounter).isNotEmpty,
        isTrue,
      );
      expect(
        ClinicalEncounterDetailSections.physiotherapyControl(encounter).isNotEmpty,
        isTrue,
      );
    });
  });
}
