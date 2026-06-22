import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/data/clinical_encounter_detail_display.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

ClinicalEncounter _encounter({String internalDoctorNote = ''}) {
  return ClinicalEncounter(
    id: 'e1',
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
    internalDoctorNote: internalDoctorNote,
  );
}

void _asRole(String role, void Function() body) {
  AuthSession.setUser(
    AppUser(
      id: 'u1',
      username: 'test',
      displayName: 'Test',
      role: role,
    ),
  );
  addTearDown(AuthSession.clear);
  body();
}

void main() {
  group('ClinicalEncounterDetailDisplay', () {
    test('internal note rows empty when assistant', () {
      _asRole(AppRoles.assistant, () {
        expect(
          ClinicalEncounterDetailDisplay.internalNoteRows(
            _encounter(internalDoctorNote: 'gizli'),
            usesRemote: true,
          ),
          isEmpty,
        );
        expect(
          ClinicalEncounterDetailDisplay.showInternalDoctorNoteSection,
          isFalse,
        );
      });
    });

    test('doctor sees Özel Not section label and value', () {
      _asRole(AppRoles.doctor, () {
        expect(
          ClinicalEncounterDetailDisplay.internalNoteSectionTitle(
            usesRemote: true,
          ),
          'Özel Not',
        );
        final rows = ClinicalEncounterDetailDisplay.internalNoteRows(
          _encounter(internalDoctorNote: 'Özel not'),
          usesRemote: true,
        );
        expect(rows, hasLength(1));
        expect(rows.first.label, 'Özel Not');
        expect(rows.first.value, 'Özel not');
      });
    });

    test('doctor empty note shows safe empty text', () {
      _asRole(AppRoles.doctor, () {
        final rows = ClinicalEncounterDetailDisplay.internalNoteRows(
          _encounter(),
          usesRemote: true,
        );
        expect(rows.single.value, 'Özel not girilmemiş.');
      });
    });
  });
}
