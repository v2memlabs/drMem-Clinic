import '../models/appointment.dart';
import '../models/appointment_slot.dart';
import '../models/clinic_schedule_config.dart';
import 'staff_leave_availability_helper.dart';

/// Randevu slot üretimi — saf mantık (UI/repository bağımsız).
abstract final class AppointmentAvailabilityService {
  static const Set<AppointmentStatus> _blockingStatuses = {
    AppointmentStatus.planlandi,
    AppointmentStatus.geldi,
    AppointmentStatus.gelmedi,
    AppointmentStatus.ertelendi,
  };

  static AppointmentAvailabilityResult buildSlots({
    required DateTime day,
    required ClinicScheduleConfig config,
    required List<Appointment> existingAppointments,
    List<StaffLeaveBusyBlock> staffLeaveBlocks = const [],
    String? excludeAppointmentId,
    DateTime? selectedSlotStart,
    DateTime? preserveCurrentSlotStart,
    int? preserveCurrentDurationMinutes,
    DateTime? now,
    bool allowPastSlots = false,
  }) {
    final calendarDay = DateTime(day.year, day.month, day.day);

    if (config.isClosedDate(calendarDay)) {
      return const AppointmentAvailabilityResult(
        slots: [],
        reason: AppointmentDayAvailabilityReason.closedDate,
        message: 'Bu tarih kapalı gün olarak işaretli.',
      );
    }

    if (!config.isActiveWeekday(calendarDay.weekday)) {
      return const AppointmentAvailabilityResult(
        slots: [],
        reason: AppointmentDayAvailabilityReason.workingDayClosed,
        message: 'Bu gün için çalışma saati tanımlı değil.',
      );
    }

    if (config.workIntervals.isEmpty) {
      return const AppointmentAvailabilityResult(
        slots: [],
        reason: AppointmentDayAvailabilityReason.workingDayClosed,
        message: 'Bu gün için çalışma saati tanımlı değil.',
      );
    }

    final referenceNow = now ?? DateTime.now();
    final busy = _busyIntervals(
      day: calendarDay,
      appointments: existingAppointments,
      excludeAppointmentId: excludeAppointmentId,
      slotDurationMinutes: config.slotDurationMinutes,
    );

    final generated = <AppointmentSlot>[];
    final seenStarts = <int>{};

    for (final interval in config.workIntervals) {
      var cursor = DateTime(
        calendarDay.year,
        calendarDay.month,
        calendarDay.day,
        interval.start.hour,
        interval.start.minute,
      );
      final intervalEnd = DateTime(
        calendarDay.year,
        calendarDay.month,
        calendarDay.day,
        interval.end.hour,
        interval.end.minute,
      );

      while (cursor.isBefore(intervalEnd)) {
        final end = cursor.add(Duration(minutes: config.slotDurationMinutes));
        if (end.isAfter(intervalEnd)) break;

        final startKey = cursor.millisecondsSinceEpoch;
        if (!seenStarts.contains(startKey)) {
          seenStarts.add(startKey);
          generated.add(
            _slotForInstant(
              start: cursor,
              end: end,
              busy: busy,
              staffLeaveBlocks: staffLeaveBlocks,
              selectedSlotStart: selectedSlotStart,
              referenceNow: referenceNow,
              allowPastSlots: allowPastSlots,
            ),
          );
        }
        cursor = end;
      }
    }

    if (preserveCurrentSlotStart != null) {
      final preserve = DateTime(
        preserveCurrentSlotStart.year,
        preserveCurrentSlotStart.month,
        preserveCurrentSlotStart.day,
        preserveCurrentSlotStart.hour,
        preserveCurrentSlotStart.minute,
      );
      final preserveKey = preserve.millisecondsSinceEpoch;
      final alreadyListed = generated.any(
        (s) =>
            s.start.hour == preserve.hour &&
            s.start.minute == preserve.minute,
      );
      if (!alreadyListed) {
        final dur = preserveCurrentDurationMinutes ?? config.slotDurationMinutes;
        final preserveEnd = preserve.add(Duration(minutes: dur));
        generated.add(
          AppointmentSlot(
            start: preserve,
            end: preserveEnd,
            isAvailable: true,
            isSelected: _sameInstant(selectedSlotStart, preserve),
            isCurrentAppointmentSlot: true,
            label: _formatTimeLabel(preserve),
          ),
        );
        seenStarts.add(preserveKey);
      } else {
        final idx = generated.indexWhere(
          (s) => s.start.hour == preserve.hour && s.start.minute == preserve.minute,
        );
        if (idx >= 0) {
          final s = generated[idx];
          generated[idx] = AppointmentSlot(
            start: s.start,
            end: s.end,
            isAvailable: s.isAvailable,
            isSelected: _sameInstant(selectedSlotStart, s.start),
            isCurrentAppointmentSlot: true,
            disabledReason: s.disabledReason,
            label: s.label,
          );
        }
      }
    }

    generated.sort((a, b) => a.start.compareTo(b.start));

    final marked = generated
        .map(
          (s) => s.copyWith(
            isSelected: _sameInstant(selectedSlotStart, s.start),
          ),
        )
        .toList();

    if (!marked.any((s) => s.isAvailable || s.isCurrentAppointmentSlot)) {
      return AppointmentAvailabilityResult(
        slots: marked,
        reason: AppointmentDayAvailabilityReason.noAvailableSlots,
        message: 'Bu gün için müsait saat bulunmuyor.',
      );
    }

    return AppointmentAvailabilityResult(slots: marked);
  }

  static bool blocksAvailability(AppointmentStatus status) =>
      _blockingStatuses.contains(status);

  static List<({DateTime start, DateTime end})> _busyIntervals({
    required DateTime day,
    required List<Appointment> appointments,
    required String? excludeAppointmentId,
    required int slotDurationMinutes,
  }) {
    final busy = <({DateTime start, DateTime end})>[];
    for (final ap in appointments) {
      if (excludeAppointmentId != null && ap.id == excludeAppointmentId) {
        continue;
      }
      if (!blocksAvailability(ap.status)) continue;

      final local = ap.appointmentDateTime.toLocal();
      if (local.year != day.year ||
          local.month != day.month ||
          local.day != day.day) {
        continue;
      }

      final start = DateTime(day.year, day.month, day.day, local.hour, local.minute);
      final dur = ap.durationMinutes > 0 ? ap.durationMinutes : slotDurationMinutes;
      busy.add((start: start, end: start.add(Duration(minutes: dur))));
    }
    return busy;
  }

  static AppointmentSlot _slotForInstant({
    required DateTime start,
    required DateTime end,
    required List<({DateTime start, DateTime end})> busy,
    required List<StaffLeaveBusyBlock> staffLeaveBlocks,
    required DateTime? selectedSlotStart,
    required DateTime referenceNow,
    required bool allowPastSlots,
  }) {
    final appointmentOverlap = busy.any(
      (b) => start.isBefore(b.end) && end.isAfter(b.start),
    );
    final leaveReason = StaffLeaveAvailabilityHelper.disabledReasonForSlot(
      start: start,
      end: end,
      blocks: staffLeaveBlocks,
    );
    final isPast = start.isBefore(referenceNow) && !allowPastSlots;
    final blocked = appointmentOverlap || leaveReason != null;
    final available = !blocked && !isPast;

    return AppointmentSlot(
      start: start,
      end: end,
      isAvailable: available,
      isSelected: _sameInstant(selectedSlotStart, start),
      disabledReason: appointmentOverlap
          ? 'Dolu'
          : leaveReason,
      label: _formatTimeLabel(start),
    );
  }

  static bool _sameInstant(DateTime? a, DateTime b) {
    if (a == null) return false;
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year &&
        x.month == y.month &&
        x.day == y.day &&
        x.hour == y.hour &&
        x.minute == y.minute;
  }

  static String _formatTimeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
