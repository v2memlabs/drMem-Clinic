import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_remote_mapper.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';

void main() {
  group('PatientRemoteMapper profile fields', () {
    test('fromRow maps gender identity nationality and emergency contact', () {
      final patient = PatientRemoteMapper.fromRow({
        'id': 'uuid-1',
        'tenant_id': 't1',
        'file_number': 'H-001',
        'first_name': 'Ali',
        'last_name': 'Veli',
        'birth_date': '1990-01-15',
        'gender': 'Erkek',
        'identity_type': 'Pasaport No',
        'national_id': 'P12345',
        'nationality': 'Almanya',
        'blood_type': 'A Rh+',
        'occupation': 'Mühendis',
        'sports_branch': 'Yüzme',
        'emergency_contact_name': 'Ayşe Veli',
        'emergency_contact_relation': 'Eş',
        'emergency_contact_phone': '05551112233',
        'insurance_type': 'SGK',
      });

      expect(patient.gender, 'Erkek');
      expect(patient.identityType, 'Pasaport No');
      expect(patient.identityNumber, 'P12345');
      expect(patient.nationality, 'Almanya');
      expect(patient.bloodType, 'A Rh+');
      expect(patient.occupation, 'Mühendis');
      expect(patient.sportBranch, 'Yüzme');
      expect(patient.emergencyContactName, 'Ayşe Veli');
      expect(patient.emergencyContactRelation, 'Eş');
      expect(patient.emergencyContactPhone, '05551112233');
    });

    test('toUpdateRow includes profile columns', () {
      final row = PatientRemoteMapper.toUpdateRow(
        Patient(
          id: 'uuid',
          fileNumber: 'H-001',
          firstName: 'Ali',
          lastName: 'Veli',
          phone: '05xx',
          birthDate: DateTime(1990, 1, 15),
          lastVisitDate: DateTime.now(),
          primaryComplaint: '',
          bodyRegion: '',
          gender: 'Kadın',
          identityType: 'T.C. Kimlik No',
          identityNumber: '11111111111',
          nationality: 'Türkiye',
          bloodType: '0 Rh+',
          occupation: 'Öğretmen',
          sportBranch: 'Tenis',
          emergencyContactName: 'Mehmet',
          emergencyContactPhone: '05550000000',
        ),
      );

      expect(row['gender'], 'Kadın');
      expect(row['identity_type'], 'T.C. Kimlik No');
      expect(row['national_id'], '11111111111');
      expect(row['nationality'], isNull);
      expect(row['blood_type'], '0 Rh+');
      expect(row['occupation'], 'Öğretmen');
      expect(row['sports_branch'], 'Tenis');
      expect(row['emergency_contact_name'], 'Mehmet');
      expect(row['emergency_contact_phone'], '05550000000');
    });

    test('unknown dropdown values normalize without crash', () {
      final patient = PatientRemoteMapper.fromRow({
        'tenant_id': 't1',
        'file_number': 'X',
        'first_name': 'A',
        'last_name': 'B',
        'gender': 'unknown_gender',
        'identity_type': 'Old Type',
        'blood_type': 'X+',
      });

      expect(patient.gender, Patient.unspecifiedLabel);
      expect(patient.identityType, Patient.defaultIdentityType);
      expect(patient.bloodType, Patient.unspecifiedLabel);
    });
  });

  group('Patient.normalizeDropdownValue', () {
    test('returns fallback when value not in list', () {
      expect(
        Patient.normalizeDropdownValue(
          'Invalid',
          Patient.genderOptions,
          Patient.unspecifiedLabel,
        ),
        Patient.unspecifiedLabel,
      );
    });
  });
}
