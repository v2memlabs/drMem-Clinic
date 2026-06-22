import 'package:flutter/material.dart';

/// Klinik işleyiş ayarları — persistence DTO (schema v1).
class ClinicWorkflowSettings {
  static const int schemaVersion = 1;
  static const List<int> allowedSlotDurations = [15, 20, 30, 45, 60];

  final int slotDurationMinutes;
  final ClinicLunchBreakSettings lunchBreak;
  final List<ClinicWeekdaySettings> weekdays;
  final List<DateTime> closedDates;

  const ClinicWorkflowSettings({
    required this.slotDurationMinutes,
    required this.lunchBreak,
    required this.weekdays,
    this.closedDates = const [],
  });

  factory ClinicWorkflowSettings.defaultClinic() {
    final defaultConfig = _defaultWeekdays();
    return ClinicWorkflowSettings(
      slotDurationMinutes: 30,
      lunchBreak: const ClinicLunchBreakSettings(
        enabled: true,
        start: TimeOfDay(hour: 12, minute: 30),
        end: TimeOfDay(hour: 13, minute: 30),
      ),
      weekdays: defaultConfig,
      closedDates: const [],
    );
  }

  static List<ClinicWeekdaySettings> _defaultWeekdays() {
    return List.generate(7, (i) {
      final weekday = i + 1;
      final enabled = weekday >= 1 && weekday <= 5;
      return ClinicWeekdaySettings(
        weekday: weekday,
        enabled: enabled,
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 0),
      );
    });
  }

  Set<int> get enabledWeekdayNumbers =>
      weekdays.where((d) => d.enabled).map((d) => d.weekday).toSet();

  ClinicWeekdaySettings? weekdaySettings(int weekday) {
    for (final d in weekdays) {
      if (d.weekday == weekday) return d;
    }
    return null;
  }
}

class ClinicWeekdaySettings {
  final int weekday;
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  const ClinicWeekdaySettings({
    required this.weekday,
    required this.enabled,
    required this.start,
    required this.end,
  });

  ClinicWeekdaySettings copyWith({
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return ClinicWeekdaySettings(
      weekday: weekday,
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

class ClinicLunchBreakSettings {
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  const ClinicLunchBreakSettings({
    required this.enabled,
    required this.start,
    required this.end,
  });

  ClinicLunchBreakSettings copyWith({
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return ClinicLunchBreakSettings(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}
