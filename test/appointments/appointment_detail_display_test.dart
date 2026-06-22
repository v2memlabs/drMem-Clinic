import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_detail_display.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

Appointment _base({
  String reason = '',
  String notes = '',
  DateTime? controlDate,
  int durationMinutes = 30,
}) {
  return Appointment(
    id: 'a1',
    patientId: 'p1',
    patientName: 'Hasta',
    appointmentDateTime: DateTime(2026, 5, 21, 10),
    durationMinutes: durationMinutes,
    type: AppointmentType.ilkMuayene,
    status: AppointmentStatus.planlandi,
    reason: reason,
    controlDate: controlDate,
    notes: notes,
  );
}

void main() {
  group('AppointmentDetailDisplay', () {
    test('remote hides default duration when reason empty', () {
      expect(
        AppointmentDetailDisplay.showDuration(
          _base(),
          usesRemote: true,
        ),
        isFalse,
      );
    });

    test('mock shows duration', () {
      expect(
        AppointmentDetailDisplay.showDuration(
          _base(),
          usesRemote: false,
        ),
        isTrue,
      );
    });

    test('reason section only when reason present', () {
      expect(AppointmentDetailDisplay.showReasonSection(_base()), isFalse);
      expect(
        AppointmentDetailDisplay.showReasonSection(_base(reason: 'Kontrol')),
        isTrue,
      );
    });

    test('control date hidden when null', () {
      expect(AppointmentDetailDisplay.showControlDate(_base()), isFalse);
      expect(
        AppointmentDetailDisplay.showControlDate(
          _base(controlDate: DateTime(2026, 6, 1)),
        ),
        isTrue,
      );
    });

    test('notes section only when notes present', () {
      expect(AppointmentDetailDisplay.showNotesSection(_base()), isFalse);
      expect(
        AppointmentDetailDisplay.showNotesSection(_base(notes: 'Not')),
        isTrue,
      );
    });
  });
}
