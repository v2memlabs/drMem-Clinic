import 'package:flutter/material.dart';

import '../../appointments/models/clinic_schedule_config.dart';
import '../models/clinic_workflow_settings.dart';

/// JSON ↔ [ClinicWorkflowSettings] ↔ [ClinicScheduleConfig].
abstract final class ClinicWorkflowSettingsMapper {
  static ClinicWorkflowSettings fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return ClinicWorkflowSettings.defaultClinic();
    }

    final version = json['schemaVersion'];
    if (version != ClinicWorkflowSettings.schemaVersion) {
      return ClinicWorkflowSettings.defaultClinic();
    }

    try {
      final slot = _parseSlotDuration(json['slotDurationMinutes']);
      final lunch = _parseLunchBreak(json['lunchBreak']);
      final weekdays = _parseWeekdays(json['weekdays']);
      final closed = _parseClosedDates(json['closedDates']);

      return ClinicWorkflowSettings(
        slotDurationMinutes: slot,
        lunchBreak: lunch,
        weekdays: weekdays,
        closedDates: closed,
      );
    } catch (_) {
      return ClinicWorkflowSettings.defaultClinic();
    }
  }

  static Map<String, dynamic> toJson(ClinicWorkflowSettings settings) {
    return {
      'schemaVersion': ClinicWorkflowSettings.schemaVersion,
      'slotDurationMinutes': settings.slotDurationMinutes,
      'lunchBreak': {
        'enabled': settings.lunchBreak.enabled,
        'start': _timeToHHmm(settings.lunchBreak.start),
        'end': _timeToHHmm(settings.lunchBreak.end),
      },
      'weekdays': settings.weekdays
          .map(
            (d) => {
              'weekday': d.weekday,
              'enabled': d.enabled,
              'start': _timeToHHmm(d.start),
              'end': _timeToHHmm(d.end),
            },
          )
          .toList(),
      'closedDates': settings.closedDates
          .map(
            (d) =>
                '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          )
          .toList(),
    };
  }

  /// Takvim seçici / genel config (gün bazlı interval kullanılmaz).
  static ClinicScheduleConfig toScheduleConfig(ClinicWorkflowSettings settings) {
    return ClinicScheduleConfig(
      activeWeekdays: settings.enabledWeekdayNumbers,
      workIntervals: const [],
      slotDurationMinutes: settings.slotDurationMinutes,
      closedDates: settings.closedDates.toSet(),
    );
  }

  /// Belirli bir gün için slot üretimi.
  static ClinicScheduleConfig toScheduleConfigForDay(
    ClinicWorkflowSettings settings,
    DateTime day,
  ) {
    final calendarDay = DateTime(day.year, day.month, day.day);
    return ClinicScheduleConfig(
      activeWeekdays: settings.enabledWeekdayNumbers,
      workIntervals: intervalsForWeekday(settings, calendarDay.weekday),
      slotDurationMinutes: settings.slotDurationMinutes,
      closedDates: settings.closedDates.toSet(),
    );
  }

  static List<ClinicTimeRange> intervalsForWeekday(
    ClinicWorkflowSettings settings,
    int weekday,
  ) {
    final day = settings.weekdaySettings(weekday);
    if (day == null || !day.enabled) return const [];

    if (!_isValidRange(day.start, day.end)) {
      return const [];
    }

    if (!settings.lunchBreak.enabled) {
      return [ClinicTimeRange(start: day.start, end: day.end)];
    }

    if (!_isValidRange(settings.lunchBreak.start, settings.lunchBreak.end)) {
      return [ClinicTimeRange(start: day.start, end: day.end)];
    }

    final lunchStart = _minutesOf(settings.lunchBreak.start);
    final lunchEnd = _minutesOf(settings.lunchBreak.end);
    final dayStart = _minutesOf(day.start);
    final dayEnd = _minutesOf(day.end);

    if (lunchStart <= dayStart || lunchEnd >= dayEnd || lunchStart >= lunchEnd) {
      return [ClinicTimeRange(start: day.start, end: day.end)];
    }

    return [
      ClinicTimeRange(
        start: day.start,
        end: settings.lunchBreak.start,
      ),
      ClinicTimeRange(
        start: settings.lunchBreak.end,
        end: day.end,
      ),
    ];
  }

  static int _parseSlotDuration(dynamic value) {
    final n = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (n != null && ClinicWorkflowSettings.allowedSlotDurations.contains(n)) {
      return n;
    }
    return 30;
  }

  static ClinicLunchBreakSettings _parseLunchBreak(dynamic value) {
    final map = value is Map ? Map<String, dynamic>.from(value) : null;
    if (map == null) {
      return ClinicWorkflowSettings.defaultClinic().lunchBreak;
    }
    final start = _parseTime(map['start']) ?? const TimeOfDay(hour: 12, minute: 30);
    final end = _parseTime(map['end']) ?? const TimeOfDay(hour: 13, minute: 30);
    return ClinicLunchBreakSettings(
      enabled: map['enabled'] == true,
      start: start,
      end: end,
    );
  }

  static List<ClinicWeekdaySettings> _parseWeekdays(dynamic value) {
    if (value is! List) {
      return ClinicWorkflowSettings.defaultClinic().weekdays;
    }

    final byWeekday = <int, ClinicWeekdaySettings>{};
    for (final item in value) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final weekday = map['weekday'] is int
          ? map['weekday'] as int
          : int.tryParse(map['weekday']?.toString() ?? '');
      if (weekday == null || weekday < 1 || weekday > 7) continue;

      final start = _parseTime(map['start']) ?? const TimeOfDay(hour: 9, minute: 0);
      final end = _parseTime(map['end']) ?? const TimeOfDay(hour: 17, minute: 0);
      var enabled = map['enabled'] == true;
      if (!_isValidRange(start, end)) {
        enabled = false;
      }

      byWeekday[weekday] = ClinicWeekdaySettings(
        weekday: weekday,
        enabled: enabled,
        start: start,
        end: end,
      );
    }

    if (byWeekday.length < 7) {
      for (final d in ClinicWorkflowSettings.defaultClinic().weekdays) {
        byWeekday.putIfAbsent(d.weekday, () => d);
      }
    }

    return List.generate(7, (i) => byWeekday[i + 1]!);
  }

  static List<DateTime> _parseClosedDates(dynamic value) {
    if (value is! List) return const [];
    final dates = <DateTime>[];
    for (final item in value) {
      final parsed = DateTime.tryParse(item.toString());
      if (parsed == null) continue;
      dates.add(DateTime(parsed.year, parsed.month, parsed.day));
    }
    return dates;
  }

  static TimeOfDay? _parseTime(dynamic value) {
    final s = value?.toString().trim();
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  static String _timeToHHmm(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  static int _minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  static bool _isValidRange(TimeOfDay start, TimeOfDay end) =>
      _minutesOf(start) < _minutesOf(end);
}
