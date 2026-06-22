import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_remote_mapper.dart';
import 'package:v2mem_clinic/features/patients/data/patient_remote_row.dart';
import 'package:v2mem_clinic/features/patients/models/patient.dart';

void main() {
  group('PatientRemoteMapper.fromRow', () {
    test('maps core DB fields to Patient', () {
      final patient = PatientRemoteMapper.fromRow({
        'id': '11111111-1111-1111-1111-111111111101',
        'tenant_id': 'tenant-a',
        'file_number': 'DEMO-001',
        'first_name': 'Demo',
        'last_name': 'Hasta',
        'phone': '+90 532 000 0000',
        'birth_date': '1980-05-10',
        'national_id': '12345678901',
        'insurance_type': 'SGK',
        'status': 'active',
        'created_at': '2026-01-01T10:00:00Z',
        'updated_at': '2026-02-01T12:00:00Z',
      });

      expect(patient.id, '11111111-1111-1111-1111-111111111101');
      expect(patient.fileNumber, 'DEMO-001');
      expect(patient.firstName, 'Demo');
      expect(patient.lastName, 'Hasta');
      expect(patient.phone, '+90 532 000 0000');
      expect(patient.birthDate.year, 1980);
      expect(patient.identityNumber, '12345678901');
      expect(patient.gender, Patient.unspecifiedLabel);
      expect(patient.insuranceType, 'SGK');
      expect(patient.primaryComplaint, '');
      expect(patient.bodyRegion, '');
      expect(patient.tags, isEmpty);
      expect(patient.tagIds, isEmpty);
      expect(patient.lastVisitDate, DateTime.parse('2026-02-01T12:00:00Z').toUtc());
    });

    test('null birth_date uses created_at day fallback', () {
      final patient = PatientRemoteMapper.fromRow({
        'id': 'id-1',
        'tenant_id': 't1',
        'file_number': 'DEMO-002',
        'first_name': 'A',
        'last_name': 'B',
        'created_at': '2015-03-20T08:00:00Z',
      });

      expect(patient.birthDate.year, 2015);
      expect(patient.birthDate.month, 3);
      expect(patient.birthDate.day, 20);
    });
  });

  group('PatientRemoteMapper.toInsertRow', () {
    test('omits id and sets tenant_id', () {
      final row = PatientRemoteMapper.toInsertRow(
        Patient(
          id: 'client-should-not-send',
          fileNumber: 'DEMO-003',
          firstName: ' Test ',
          lastName: ' User ',
          phone: '',
          birthDate: DateTime(1990, 7, 1),
          lastVisitDate: DateTime.now(),
          primaryComplaint: '-',
          bodyRegion: '-',
          identityNumber: '',
        ),
        tenantId: 'tenant-scope-id',
      );

      expect(row.containsKey('id'), isFalse);
      expect(row['tenant_id'], 'tenant-scope-id');
      expect(row['file_number'], 'DEMO-003');
      expect(row['first_name'], 'Test');
      expect(row['last_name'], 'User');
      expect(row['phone'], isNull);
      expect(row['birth_date'], '1990-07-01');
      expect(row['status'], 'active');
      expect(row.containsKey('created_at'), isFalse);
      expect(row.containsKey('deleted_at'), isFalse);
    });
  });

  group('PatientRemoteMapper.toUpdateRow', () {
    test('does not change tenant_id or file_number', () {
      final row = PatientRemoteMapper.toUpdateRow(
        Patient(
          id: 'uuid',
          fileNumber: 'DEMO-001',
          firstName: 'Ada',
          lastName: 'Lovelace',
          phone: Patient.unspecifiedLabel,
          birthDate: DateTime(1815, 12, 10),
          lastVisitDate: DateTime.now(),
          primaryComplaint: 'x',
          bodyRegion: 'y',
        ),
      );

      expect(row.containsKey('tenant_id'), isFalse);
      expect(row.containsKey('id'), isFalse);
      expect(row.containsKey('file_number'), isFalse);
      expect(row['first_name'], 'Ada');
      expect(row.containsKey('deleted_at'), isFalse);
    });
  });

  group('PatientRemoteMapper.toSoftDeleteRow', () {
    test('sets deleted_at and archived status', () {
      final at = DateTime.utc(2026, 5, 22, 14, 30);
      final row = PatientRemoteMapper.toSoftDeleteRow(at: at);

      expect(row['status'], 'archived');
      expect(row['deleted_at'], at.toIso8601String());
    });
  });

  group('PatientRemoteRow.fromMap', () {
    test('round-trip map keys', () {
      final row = PatientRemoteRow.fromMap({
        'tenant_id': 't1',
        'file_number': 'F-1',
        'first_name': 'X',
        'last_name': 'Y',
        'gender': 'female',
      });
      expect(row.gender, 'female');
      expect(row.toMap(includeId: false)['tenant_id'], 't1');
    });
  });
}
