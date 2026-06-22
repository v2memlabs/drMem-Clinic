import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_list_refresh.dart';
import 'package:v2mem_clinic/features/patients/data/patient_remote_mapper.dart';
import 'package:v2mem_clinic/features/patients/data/quick_patient_create_data_source.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';

void main() {
  group('QuickPatientCreateDataSource.buildDraft', () {
    test('uses empty clinical placeholders and fallback birth', () {
      final draft = QuickPatientCreateDataSource.buildDraft(
        fileNumber: 'H-TEST-0001',
        firstName: 'Ayşe',
        lastName: 'Demir',
        phone: '05321234567',
      );

      expect(draft.primaryComplaint, '');
      expect(draft.bodyRegion, '');
      expect(draft.birthDate, PatientRemoteMapper.fallbackBirthDate);
      expect(draft.firstName, 'Ayşe');
      expect(draft.phone, '05321234567');
    });

    test('uses provided birth date when given', () {
      final birth = DateTime(1985, 6, 15);
      final draft = QuickPatientCreateDataSource.buildDraft(
        fileNumber: 'H-TEST-0002',
        firstName: 'Mehmet',
        lastName: 'Kaya',
        phone: '05329876543',
        birthDate: birth,
      );
      expect(draft.birthDate, birth);
    });
  });

  group('normalizePhone', () {
    test('strips formatting and compares last 10 digits', () {
      expect(
        QuickPatientCreateDataSource.normalizePhone('+90 532 111 2233'),
        QuickPatientCreateDataSource.normalizePhone('05321112233'),
      );
    });
  });

  group('findSimilarPatients', () {
    test('finds mock patient with matching phone', () async {
      final similar = await QuickPatientCreateDataSource.findSimilarPatients(
        firstName: 'Ahmet',
        lastName: 'Yılmaz',
        phone: '05321112233',
      );
      expect(similar, isNotEmpty);
      expect(similar.first.firstName, 'Ahmet');
    });

    test('returns empty for unrelated phone', () async {
      final similar = await QuickPatientCreateDataSource.findSimilarPatients(
        firstName: 'Benzersiz',
        lastName: 'Hasta',
        phone: '05999999999',
      );
      expect(similar, isEmpty);
    });
  });

  group('isProfilePartiallyComplete', () {
    test('true when fallback birth or unspecified gender', () {
      final draft = QuickPatientCreateDataSource.buildDraft(
        fileNumber: 'H-1',
        firstName: 'A',
        lastName: 'B',
        phone: '05321112299',
      );
      expect(
        QuickPatientCreateDataSource.isProfilePartiallyComplete(draft),
        isTrue,
      );

      final withGender = draft.copyWith(
        gender: 'Erkek',
        birthDate: DateTime(1990, 1, 1),
        identityNumber: '11111111110',
      );
      expect(
        QuickPatientCreateDataSource.isProfilePartiallyComplete(withGender),
        isFalse,
      );
    });
  });

  test('createQuickPatient marks patient list stale', () async {
    final before = PatientListRefresh.version;
    final created = await QuickPatientCreateDataSource.createQuickPatient(
      firstName: 'Hızlı',
      lastName: 'Kayıt',
      phone: '05324445566',
    );
    expect(created.id, isNotEmpty);
    expect(created.fullName, contains('Hızlı'));
    expect(PatientListRefresh.version, greaterThan(before));
  });
}
