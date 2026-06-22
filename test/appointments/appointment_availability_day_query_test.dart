import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/mock_async_appointment_repository_adapter.dart';
import 'package:v2mem_clinic/features/appointments/models/appointment.dart';

void main() {
  group('getForCalendarDay mock', () {
    final adapter = MockAsyncAppointmentRepositoryAdapter();

    test('returns only appointments on the same calendar day', () async {
      final all = await adapter.getAll();
      expect(all, isNotEmpty);

      final sample = all.first;
      final local = sample.appointmentDateTime.toLocal();
      final day = DateTime(local.year, local.month, local.day);

      final forDay = await adapter.getForCalendarDay(day);

      expect(forDay, isNotEmpty);
      for (final ap in forDay) {
        final l = ap.appointmentDateTime.toLocal();
        expect(l.year, day.year);
        expect(l.month, day.month);
        expect(l.day, day.day);
      }

      final otherDay = day.add(const Duration(days: 1));
      final other = await adapter.getForCalendarDay(otherDay);
      final overlapIds = forDay.map((e) => e.id).toSet();
      for (final ap in other) {
        expect(overlapIds.contains(ap.id), isFalse);
      }
    });

    test('includes cancelled appointments for service filtering', () async {
      final all = await adapter.getAll();
      final cancelled = all.where((a) => a.status == AppointmentStatus.iptal);
      if (cancelled.isEmpty) return;

      final ap = cancelled.first;
      final local = ap.appointmentDateTime.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final forDay = await adapter.getForCalendarDay(day);
      expect(forDay.any((e) => e.id == ap.id), isTrue);
    });
  });
}
