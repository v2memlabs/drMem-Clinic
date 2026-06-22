import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_profile_completion.dart';
import 'package:v2mem_clinic/features/patients/data/patient_remote_mapper.dart';
import 'package:v2mem_clinic/features/patients/data/quick_patient_create_data_source.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';

void main() {
  Patient completePatient() => Patient(
        id: 'p-complete',
        fileNumber: 'H-2026-9999',
        firstName: 'Tam',
        lastName: 'Profil',
        phone: '05321112233',
        birthDate: DateTime(1985, 3, 20),
        lastVisitDate: DateTime.now(),
        primaryComplaint: '—',
        bodyRegion: '—',
        gender: 'Erkek',
        identityNumber: '12345678901',
      );

  group('PatientProfileCompletion.evaluate', () {
    test('complete patient has no missing fields', () {
      final status = PatientProfileCompletion.evaluate(completePatient());
      expect(status.isComplete, isTrue);
      expect(status.missingFields, isEmpty);
      expect(status.missingLabels, isEmpty);
    });

    test('fallback birth date marks birthDate missing', () {
      final patient = completePatient().copyWith(
        birthDate: PatientRemoteMapper.fallbackBirthDate,
      );
      final status = PatientProfileCompletion.evaluate(patient);
      expect(status.isComplete, isFalse);
      expect(status.missingFields, contains(PatientProfileMissingField.birthDate));
      expect(status.missingLabels, contains('Doğum tarihi'));
    });

    test('unspecified gender marks gender missing', () {
      final patient = completePatient().copyWith(
        gender: Patient.unspecifiedLabel,
      );
      final status = PatientProfileCompletion.evaluate(patient);
      expect(status.missingFields, contains(PatientProfileMissingField.gender));
      expect(status.missingLabels, contains('Cinsiyet'));
    });

    test('invalid phone marks phone missing', () {
      final patient = completePatient().copyWith(phone: '-');
      final status = PatientProfileCompletion.evaluate(patient);
      expect(status.missingFields, contains(PatientProfileMissingField.phone));
      expect(status.missingLabels, contains('Telefon'));
    });

    test('empty identity marks identity missing', () {
      final patient = completePatient().copyWith(identityNumber: '');
      final status = PatientProfileCompletion.evaluate(patient);
      expect(status.missingFields, contains(PatientProfileMissingField.identity));
      expect(status.missingLabels, contains('Kimlik bilgisi'));
    });

    test('displayFields capped at 3 and hasMore when needed', () {
      final patient = Patient(
        id: 'p-many',
        fileNumber: 'H-1',
        firstName: 'E',
        lastName: 'K',
        phone: '-',
        birthDate: PatientRemoteMapper.fallbackBirthDate,
        lastVisitDate: DateTime.now(),
        primaryComplaint: '',
        bodyRegion: '',
        gender: Patient.unspecifiedLabel,
        identityNumber: '',
      );
      final status = PatientProfileCompletion.evaluate(patient);
      expect(status.displayFields.length, 3);
      expect(status.hasMore, isTrue);
      expect(status.missingFields.length, 4);
    });

    test('quick create draft defaults are incomplete', () {
      final draft = QuickPatientCreateDataSource.buildDraft(
        fileNumber: 'H-Q-1',
        firstName: 'Hızlı',
        lastName: 'Kayıt',
        phone: '05324445566',
      );
      final status = PatientProfileCompletion.evaluate(draft);
      expect(status.isComplete, isFalse);
      expect(
        QuickPatientCreateDataSource.isProfilePartiallyComplete(draft),
        isTrue,
      );
    });
  });
}
