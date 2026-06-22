import '../../settings/models/staff_leave_record.dart';

/// Personel izin kaydı → takvim günü için meşgul aralık.
class StaffLeaveBusyBlock {
  final DateTime start;
  final DateTime end;
  final String staffDisplayName;

  const StaffLeaveBusyBlock({
    required this.start,
    required this.end,
    required this.staffDisplayName,
  });
}

/// Aktif personel izinlerini randevu slotlarıyla kıyaslanabilir aralıklara dönüştürür.
///
/// Randevu modelinde personel ataması olmadığı için v2'de tüm aktif izinler
/// klinik geneli slot kapatma olarak uygulanır.
abstract final class StaffLeaveAvailabilityHelper {
  static List<StaffLeaveBusyBlock> blocksForDay({
    required DateTime calendarDay,
    required List<StaffLeaveRecord> leaves,
  }) {
    final dayStart = DateTime(
      calendarDay.year,
      calendarDay.month,
      calendarDay.day,
    );
    final dayEndExclusive = dayStart.add(const Duration(days: 1));
    final blocks = <StaffLeaveBusyBlock>[];

    for (final leave in leaves) {
      if (!leave.isActive) continue;

      final leaveStart = leave.startsAt.toLocal();
      final leaveEnd = leave.endsAt.toLocal();
      if (!leaveEnd.isAfter(dayStart) || !leaveStart.isBefore(dayEndExclusive)) {
        continue;
      }

      final effectiveStart =
          leaveStart.isBefore(dayStart) ? dayStart : leaveStart;
      final effectiveEnd =
          leaveEnd.isAfter(dayEndExclusive) ? dayEndExclusive : leaveEnd;

      blocks.add(
        StaffLeaveBusyBlock(
          start: DateTime(
            calendarDay.year,
            calendarDay.month,
            calendarDay.day,
            effectiveStart.hour,
            effectiveStart.minute,
          ),
          end: effectiveEnd == dayEndExclusive
              ? dayEndExclusive
              : DateTime(
                  calendarDay.year,
                  calendarDay.month,
                  calendarDay.day,
                  effectiveEnd.hour,
                  effectiveEnd.minute,
                ),
          staffDisplayName: leave.staffDisplayName,
        ),
      );
    }

    return blocks;
  }

  static String? disabledReasonForSlot({
    required DateTime start,
    required DateTime end,
    required List<StaffLeaveBusyBlock> blocks,
  }) {
    for (final block in blocks) {
      if (start.isBefore(block.end) && end.isAfter(block.start)) {
        return 'İzinli: ${block.staffDisplayName}';
      }
    }
    return null;
  }
}
