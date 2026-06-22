import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/data/staff_leave_availability_helper.dart';
import 'package:v2mem_clinic/features/settings/models/staff_leave_record.dart';

StaffLeaveRecord _leave({
  required DateTime startsAt,
  required DateTime endsAt,
  StaffLeaveStatus status = StaffLeaveStatus.active,
  String name = 'Dr. Test',
}) {
  final now = DateTime.now();
  return StaffLeaveRecord(
    id: 'leave-1',
    staffDisplayName: name,
    leaveType: StaffLeaveType.annual,
    startsAt: startsAt,
    endsAt: endsAt,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final monday = DateTime(2026, 5, 25);

  group('StaffLeaveAvailabilityHelper', () {
    test('same-day leave produces clipped block', () {
      final blocks = StaffLeaveAvailabilityHelper.blocksForDay(
        calendarDay: monday,
        leaves: [
          _leave(
            startsAt: DateTime(2026, 5, 25, 10, 0),
            endsAt: DateTime(2026, 5, 25, 12, 0),
          ),
        ],
      );
      expect(blocks, hasLength(1));
      expect(blocks.first.start, DateTime(2026, 5, 25, 10, 0));
      expect(blocks.first.end, DateTime(2026, 5, 25, 12, 0));
    });

    test('multi-day leave blocks full working day', () {
      final blocks = StaffLeaveAvailabilityHelper.blocksForDay(
        calendarDay: monday,
        leaves: [
          _leave(
            startsAt: DateTime(2026, 5, 24, 9, 0),
            endsAt: DateTime(2026, 5, 26, 18, 0),
          ),
        ],
      );
      expect(blocks, hasLength(1));
      expect(blocks.first.start, DateTime(2026, 5, 25, 0, 0));
      expect(
        blocks.first.end,
        DateTime(2026, 5, 26, 0, 0),
      );
    });

    test('cancelled leave is ignored', () {
      final blocks = StaffLeaveAvailabilityHelper.blocksForDay(
        calendarDay: monday,
        leaves: [
          _leave(
            startsAt: DateTime(2026, 5, 25, 9, 0),
            endsAt: DateTime(2026, 5, 25, 18, 0),
            status: StaffLeaveStatus.cancelled,
          ),
        ],
      );
      expect(blocks, isEmpty);
    });

    test('disabledReasonForSlot returns staff name', () {
      final blocks = StaffLeaveAvailabilityHelper.blocksForDay(
        calendarDay: monday,
        leaves: [
          _leave(
            startsAt: DateTime(2026, 5, 25, 9, 0),
            endsAt: DateTime(2026, 5, 25, 10, 0),
            name: 'Uzm. Ayşe',
          ),
        ],
      );
      final reason = StaffLeaveAvailabilityHelper.disabledReasonForSlot(
        start: DateTime(2026, 5, 25, 9, 0),
        end: DateTime(2026, 5, 25, 9, 30),
        blocks: blocks,
      );
      expect(reason, 'İzinli: Uzm. Ayşe');
    });
  });
}
