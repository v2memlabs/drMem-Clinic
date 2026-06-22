import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_list_display.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

Appointment _base({String reason = '', String notes = ''}) {
  return Appointment(
    id: 'a1',
    patientId: 'p1',
    patientName: 'Hasta',
    appointmentDateTime: DateTime(2026, 5, 21, 10),
    durationMinutes: 30,
    type: AppointmentType.ilkMuayene,
    status: AppointmentStatus.planlandi,
    reason: reason,
    controlDate: null,
    notes: notes,
  );
}

void main() {
  group('AppointmentListDisplay.cardMetaLine', () {
    test('remote with notes shows notes not duration fallback', () {
      final line = AppointmentListDisplay.cardMetaLine(
        _base(notes: 'Kontrol notu'),
        usesRemote: true,
      );
      expect(line, 'Kontrol notu');
    });

    test('remote without reason or notes returns null', () {
      expect(
        AppointmentListDisplay.cardMetaLine(_base(), usesRemote: true),
        isNull,
      );
    });

    test('mock without reason still shows duration', () {
      expect(
        AppointmentListDisplay.cardMetaLine(_base(), usesRemote: false),
        '30 dk',
      );
    });

    test('reason present includes duration', () {
      final line = AppointmentListDisplay.cardMetaLine(
        _base(reason: 'Kontrol'),
        usesRemote: true,
      );
      expect(line, 'Kontrol • 30 dk');
    });
  });
}
