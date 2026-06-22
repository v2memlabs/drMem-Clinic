import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/appointment_day_availability_summary.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment_slot.dart';

void main() {
  group('AppointmentDayAvailabilitySummary', () {
    test('slotStatsLabel returns boş slot count', () {
      final result = AppointmentAvailabilityResult(
        slots: [
          AppointmentSlot(
            start: DateTime(2026, 6, 7, 9),
            end: DateTime(2026, 6, 7, 9, 30),
            isAvailable: true,
            label: '09:00',
          ),
          AppointmentSlot(
            start: DateTime(2026, 6, 7, 9, 30),
            end: DateTime(2026, 6, 7, 10),
            isAvailable: false,
            label: '09:30',
          ),
        ],
      );
      expect(
        AppointmentDayAvailabilitySummary.slotStatsLabel(result),
        '1 boş slot',
      );
    });

    test('slotStatsLabel handles closed day', () {
      const result = AppointmentAvailabilityResult(
        slots: [],
        reason: AppointmentDayAvailabilityReason.closedDate,
        message: 'Resmi tatil',
      );
      expect(
        AppointmentDayAvailabilitySummary.slotStatsLabel(result),
        'Resmi tatil',
      );
    });
  });
}
