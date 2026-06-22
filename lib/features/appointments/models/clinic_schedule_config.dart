import 'package:flutter/material.dart';

/// Klinik mesai / slot ayarları (v1: in-memory default; persistence ayrı paket).
class ClinicScheduleConfig {
  /// [DateTime.weekday] değerleri: 1 = Pazartesi … 7 = Pazar.
  final Set<int> activeWeekdays;
  final List<ClinicTimeRange> workIntervals;
  final int slotDurationMinutes;
  final Set<DateTime> closedDates;

  const ClinicScheduleConfig({
    required this.activeWeekdays,
    required this.workIntervals,
    required this.slotDurationMinutes,
    this.closedDates = const {},
  });

  /// Pazartesi–Cuma 09:00–17:00, öğle 12:30–13:30 kapalı, 30 dk slot.
  factory ClinicScheduleConfig.defaultClinic() {
    return ClinicScheduleConfig(
      activeWeekdays: const {1, 2, 3, 4, 5},
      workIntervals: const [
        ClinicTimeRange(
          start: TimeOfDay(hour: 9, minute: 0),
          end: TimeOfDay(hour: 12, minute: 30),
        ),
        ClinicTimeRange(
          start: TimeOfDay(hour: 13, minute: 30),
          end: TimeOfDay(hour: 17, minute: 0),
        ),
      ],
      slotDurationMinutes: 30,
      closedDates: const {},
    );
  }

  bool isActiveWeekday(int weekday) => activeWeekdays.contains(weekday);

  bool isClosedDate(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return closedDates.any(
      (d) => d.year == key.year && d.month == key.month && d.day == key.day,
    );
  }

  /// Form açılışında: bugün veya önümüzdeki ilk çalışma günü.
  DateTime firstSelectableDay({DateTime? from}) {
    final start = from ?? DateTime.now();
    for (var i = 0; i < 14; i++) {
      final day = DateTime(start.year, start.month, start.day).add(Duration(days: i));
      if (isActiveWeekday(day.weekday) && !isClosedDate(day)) {
        return day;
      }
    }
    return DateTime(start.year, start.month, start.day);
  }
}

class ClinicTimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const ClinicTimeRange({required this.start, required this.end});
}
