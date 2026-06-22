import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/patients/data/patient_file_number_helper.dart';
import 'package:v2mem_clinic/features/settings/models/patient_registration_settings.dart';

void main() {
  group('PatientFileNumberHelper', () {
    test('continues DEMO-{seq} format', () {
      const settings = PatientRegistrationSettings(
        fileNumberFormat: 'DEMO-{seq}',
        seqPadding: 3,
      );
      final next = PatientFileNumberHelper.nextFromExisting(
        ['DEMO-001', 'DEMO-002'],
        settings: settings,
        year: 2026,
      );
      expect(next, 'DEMO-003');
    });

    test('uses H-{year}-{seq} default', () {
      final next = PatientFileNumberHelper.nextFromExisting(
        ['H-2026-0001', 'H-2026-0009'],
        year: 2026,
      );
      expect(next, 'H-2026-0010');
    });

    test('empty list uses default format', () {
      final next = PatientFileNumberHelper.nextFromExisting([], year: 2026);
      expect(next, 'H-2026-0001');
    });

    test('A-{seq} format with padding', () {
      const settings = PatientRegistrationSettings(
        fileNumberFormat: 'A-{seq}',
        seqPadding: 3,
      );
      final next = PatientFileNumberHelper.nextFromExisting(
        ['A-012'],
        settings: settings,
      );
      expect(next, 'A-013');
    });

    test('year in format scopes sequence per year', () {
      final next = PatientFileNumberHelper.nextFromExisting(
        ['H-2025-0099', 'H-2026-0003'],
        year: 2026,
      );
      expect(next, 'H-2026-0004');
    });
  });
}
