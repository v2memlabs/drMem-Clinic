import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_list_filters.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

Appointment _appointment({
  required DateTime when,
  AppointmentStatus status = AppointmentStatus.planlandi,
  String patientId = 'p1',
}) {
  return Appointment(
    id: 'a1',
    patientId: patientId,
    patientName: 'Test Hasta',
    appointmentDateTime: when,
    durationMinutes: 30,
    type: AppointmentType.ilkMuayene,
    status: status,
    reason: '',
    controlDate: null,
    notes: '',
  );
}

void main() {
  group('AppointmentListFilters', () {
    test('applyStatus filters by status', () {
      final planned = _appointment(when: DateTime(2026, 5, 21, 10));
      final cancelled = _appointment(
        when: DateTime(2026, 5, 21, 11),
        status: AppointmentStatus.iptal,
      );
      final result = AppointmentListFilters.applyStatus(
        [planned, cancelled],
        AppointmentStatus.iptal,
      );
      expect(result, [cancelled]);
    });

    test('applyPeriod today keeps same calendar day', () {
      final now = DateTime.now();
      final today = _appointment(when: now);
      final tomorrow = _appointment(when: now.add(const Duration(days: 1)));
      final result = AppointmentListFilters.applyPeriod(
        [today, tomorrow],
        'today',
      );
      expect(result, [today]);
    });
  });
}
