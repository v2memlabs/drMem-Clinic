import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_calendar_helper.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

void main() {
  group('AppointmentCalendarHelper', () {
    test('mondayWeekStart returns Monday for Wednesday', () {
      final wed = DateTime(2026, 6, 3);
      final start = AppointmentCalendarHelper.mondayWeekStart(wed);
      expect(start.weekday, DateTime.monday);
      expect(start.day, 1);
      expect(start.month, 6);
    });

    test('daysInWeek returns 7 consecutive days', () {
      final start = DateTime(2026, 6, 1);
      final days = AppointmentCalendarHelper.daysInWeek(start);
      expect(days, hasLength(7));
      expect(days.first.day, 1);
      expect(days.last.day, 7);
    });

    test('sameWeekdayInWeek preserves weekday when shifting', () {
      final thursday = DateTime(2026, 6, 4);
      final nextWeek = AppointmentCalendarHelper.mondayWeekStart(
        thursday.add(const Duration(days: 7)),
      );
      final shifted = AppointmentCalendarHelper.sameWeekdayInWeek(
        nextWeek,
        thursday.weekday,
      );
      expect(shifted.weekday, DateTime.thursday);
      expect(shifted.day, 11);
    });

    test('appointmentOnDay matches local calendar day', () {
      final appt = Appointment(
        id: 'a1',
        patientId: 'p1',
        patientName: 'Test',
        appointmentDateTime: DateTime(2026, 6, 7, 14, 30),
        durationMinutes: 30,
        type: AppointmentType.kontrol,
        status: AppointmentStatus.planlandi,
        reason: '',
        controlDate: null,
        notes: '',
      );
      expect(
        AppointmentCalendarHelper.appointmentOnDay(appt, DateTime(2026, 6, 7)),
        isTrue,
      );
      expect(
        AppointmentCalendarHelper.appointmentOnDay(appt, DateTime(2026, 6, 8)),
        isFalse,
      );
    });
  });
}
