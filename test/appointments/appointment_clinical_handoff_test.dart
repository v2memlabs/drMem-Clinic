import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_clinical_handoff.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

Appointment _appointment({required AppointmentStatus status}) {
  return Appointment(
    id: 'a-test',
    patientId: 'p1',
    patientName: 'Test Hasta',
    appointmentDateTime: DateTime(2026, 5, 28, 10),
    durationMinutes: 30,
    type: AppointmentType.ilkMuayene,
    status: status,
    reason: 'Test',
  );
}

void main() {
  group('AppointmentClinicalHandoff.canShowStartEncounter', () {
    test('planlandi with patient shows', () {
      expect(
        AppointmentClinicalHandoff.canShowStartEncounter(
          canEditClinicalEncounters: true,
          patientId: 'p1',
          status: AppointmentStatus.planlandi,
        ),
        isTrue,
      );
    });

    test('ertelendi with patient shows', () {
      expect(
        AppointmentClinicalHandoff.canShowStartEncounter(
          canEditClinicalEncounters: true,
          patientId: 'p1',
          status: AppointmentStatus.ertelendi,
        ),
        isTrue,
      );
    });

    test('geldi with patient shows', () {
      expect(
        AppointmentClinicalHandoff.canShowStartEncounter(
          canEditClinicalEncounters: true,
          patientId: 'p1',
          status: AppointmentStatus.geldi,
        ),
        isTrue,
      );
    });

    test('iptal hidden', () {
      expect(
        AppointmentClinicalHandoff.canShowStartEncounter(
          canEditClinicalEncounters: true,
          patientId: 'p1',
          status: AppointmentStatus.iptal,
        ),
        isFalse,
      );
    });

    test('gelmedi hidden', () {
      expect(
        AppointmentClinicalHandoff.canShowStartEncounter(
          canEditClinicalEncounters: true,
          patientId: 'p1',
          status: AppointmentStatus.gelmedi,
        ),
        isFalse,
      );
    });

    test('no edit permission hidden', () {
      expect(
        AppointmentClinicalHandoff.canShowStartEncounter(
          canEditClinicalEncounters: false,
          patientId: 'p1',
          status: AppointmentStatus.planlandi,
        ),
        isFalse,
      );
    });

    test('missing patient hidden', () {
      expect(
        AppointmentClinicalHandoff.canShowStartEncounter(
          canEditClinicalEncounters: true,
          patientId: '',
          status: AppointmentStatus.planlandi,
        ),
        isFalse,
      );
    });
  });

  group('AppointmentClinicalHandoff status update', () {
    test('planlandi becomes geldi', () {
      final updated = AppointmentClinicalHandoff.withArrivedStatus(
        _appointment(status: AppointmentStatus.planlandi),
      );
      expect(updated.status, AppointmentStatus.geldi);
    });

    test('ertelendi becomes geldi', () {
      final updated = AppointmentClinicalHandoff.withArrivedStatus(
        _appointment(status: AppointmentStatus.ertelendi),
      );
      expect(updated.status, AppointmentStatus.geldi);
    });

    test('geldi unchanged', () {
      final original = _appointment(status: AppointmentStatus.geldi);
      final updated = AppointmentClinicalHandoff.withArrivedStatus(original);
      expect(updated.status, AppointmentStatus.geldi);
      expect(identical(updated, original), isTrue);
    });
  });

  group('AppointmentClinicalHandoff route', () {
    test('buildNewEncounterLocation includes query params', () {
      final location = AppointmentClinicalHandoff.buildNewEncounterLocation(
        patientId: 'p1',
        appointmentId: 'a1',
      );
      expect(location, contains('/clinical-records/new'));
      expect(location, contains('patientId=p1'));
      expect(location, contains('appointmentId=a1'));
    });
  });
}
