import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_encounter.dart';
import 'package:v2mem_clinic/features/clinical_encounter/models/clinical_treatment_approach.dart';
import 'package:v2mem_clinic/features/clinical_encounter/widgets/clinical_encounter_identity_band.dart';
import 'package:v2mem_clinic/features/patients/data/mock_patients.dart';
import 'package:v2mem_clinic/features/patients/data/patient_identity_privacy.dart';
import 'package:v2mem_clinic/features/patients/data/patient_repository.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';
import 'package:v2mem_clinic/features/patients/patient_display_helpers.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
  });

  group('PatientIdentityPrivacy', () {
    test('TC mask 12345678901 → 12*******01', () {
      expect(
        PatientIdentityPrivacy.maskTurkishNationalId('12345678901'),
        '12*******01',
      );
    });

    test('kısa/boş/geçersiz TC → null', () {
      expect(PatientIdentityPrivacy.maskTurkishNationalId(null), isNull);
      expect(PatientIdentityPrivacy.maskTurkishNationalId(''), isNull);
      expect(PatientIdentityPrivacy.maskTurkishNationalId('123'), isNull);
      expect(PatientIdentityPrivacy.maskTurkishNationalId('abcdefghijk'), isNull);
    });

    test('telefon maskesi okunabilir format', () {
      expect(
        PatientIdentityPrivacy.formatMaskedPhone('05321234567'),
        '05xx xxx 45 67',
      );
    });

    test('formatIdentityLineForDisplay maskeli TC satırı', () {
      AuthSession.setUser(
        AppUser(
          id: 'doc',
          username: 'doc@test.com',
          displayName: 'Dr',
          role: AppRoles.doctor,
        ),
      );

      final patient = mockPatients.first.copyWith(
        identityType: Patient.defaultIdentityType,
        identityNumber: '12345678901',
      );

      expect(
        PatientIdentityPrivacy.formatIdentityLineForDisplay(patient),
        'T.C. Kimlik No: 12*******01',
      );
      expect(
        PatientIdentityPrivacy.displayIdentityNumber(patient),
        '12*******01',
      );
    });

    test('formatIdentityLineForDisplay ham TC döndürmez', () {
      AuthSession.setUser(
        AppUser(
          id: 'doc',
          username: 'doc@test.com',
          displayName: 'Dr',
          role: AppRoles.doctor,
        ),
      );

      final patient = mockPatients.first.copyWith(
        identityType: Patient.defaultIdentityType,
        identityNumber: '12345678901',
      );

      expect(
        PatientIdentityPrivacy.formatIdentityLineForDisplay(patient),
        isNot(contains('12345678901')),
      );
    });

    test('fizyoterapist hasta detay kimlik satırı görmez', () {
      AuthSession.setUser(
        AppUser(
          id: 'phy',
          username: 'phy@test.com',
          displayName: 'FTR',
          role: AppRoles.physiotherapist,
        ),
      );

      final patient = mockPatients.first.copyWith(
        identityType: Patient.defaultIdentityType,
        identityNumber: '12345678901',
      );

      expect(PatientIdentityPrivacy.formatIdentityLineForDisplay(patient), isNull);
      expect(PatientIdentityPrivacy.displayIdentityNumber(patient), isNull);
    });
  });

  group('ClinicalEncounterIdentityBand', () {
    late Patient patient;
    late ClinicalEncounter encounter;

    setUp(() {
      patient = mockPatients.first.copyWith(
        id: 'p-band-test',
        firstName: 'Ali',
        lastName: 'Yılmaz',
        phone: '05321234567',
        gender: 'Erkek',
        identityType: Patient.defaultIdentityType,
        identityNumber: '12345678901',
        birthDate: DateTime(1978, 3, 15),
      );
      PatientRepository.instance.add(patient);

      encounter = ClinicalEncounter(
        id: 'ce-band-1',
        patientId: patient.id,
        patientName: 'Yılmaz, Ali',
        createdAt: DateTime(2026, 5, 20),
        updatedAt: DateTime(2026, 5, 20),
        doctorName: 'Dr. Test',
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
        preliminaryDiagnosis: '',
        finalDiagnosis: '',
        differentialDiagnosis: '',
        diagnosisType: ClinicalDiagnosisType.dejeneratif,
        icdCode: '',
        icdTitle: '',
        planTitle: '',
        conservativeTreatment: '',
        medicationNotes: '',
        injectionOrProcedurePlan: '',
        physiotherapyReferral: false,
        exerciseRecommendation: '',
        imagingRequest: '',
        controlDate: DateTime(2026, 6, 1),
        surgeryRecommendation: '',
        patientInformationNote: '',
        warningNotes: '',
        internalDoctorNote: '',
        orthosisNotes: '',
        treatmentApproach: ClinicalTreatmentApproach.conservative,
      );
    });

    testWidgets('detay bandında ad, demografi, maskeli TC; ham TC yok', (tester) async {
      AuthSession.setUser(
        AppUser(
          id: 'doc',
          username: 'doc@test.com',
          displayName: 'Dr',
          role: AppRoles.doctor,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEncounterIdentityBand.fromEncounter(encounter),
          ),
        ),
      );

      expect(find.text('Ali Yılmaz'), findsOneWidget);
      expect(find.textContaining('yaş'), findsOneWidget);
      expect(find.textContaining('Erkek'), findsOneWidget);
      expect(find.textContaining('05xx xxx 45 67'), findsOneWidget);
      expect(find.textContaining('12*******01'), findsOneWidget);
      expect(find.textContaining('12345678901'), findsNothing);
    });

    testWidgets('fizyoterapist maskeli TC görmez', (tester) async {
      AuthSession.setUser(
        AppUser(
          id: 'phy',
          username: 'phy@test.com',
          displayName: 'FTR',
          role: AppRoles.physiotherapist,
        ),
      );

      final line = PatientIdentityPrivacy.maskedNationalIdLine(patient);
      expect(line, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClinicalEncounterIdentityBand.fromPatientDetail(
              encounter: encounter,
              patient: patient,
            ),
          ),
        ),
      );

      expect(find.textContaining('12*******01'), findsNothing);
      expect(find.textContaining('12345678901'), findsNothing);
    });

    test('demografi satırı ham kimlik içermez', () {
      final line = PatientDisplayHelpers.formatEncounterIdentityDemographyLine(
        patient,
      );
      expect(line, isNotNull);
      expect(line!.contains('12345678901'), isFalse);
      expect(line.contains('yaş'), isTrue);
    });
  });
}
