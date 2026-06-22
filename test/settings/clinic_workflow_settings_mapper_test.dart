import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/appointments/models/clinic_schedule_config.dart';
import 'package:v2mem_clinic/features/settings/data/clinic_workflow_settings_mapper.dart';
import 'package:v2mem_clinic/features/settings/models/clinic_workflow_settings.dart';

void main() {
  group('ClinicWorkflowSettingsMapper', () {
    test('parses valid JSON', () {
      final json = ClinicWorkflowSettingsMapper.toJson(
        ClinicWorkflowSettings.defaultClinic(),
      );
      final settings = ClinicWorkflowSettingsMapper.fromJson(json);
      expect(settings.slotDurationMinutes, 30);
      expect(settings.weekdays.length, 7);
      expect(settings.lunchBreak.enabled, isTrue);
    });

    test('missing or invalid JSON falls back to default', () {
      expect(
        ClinicWorkflowSettingsMapper.fromJson(null).slotDurationMinutes,
        30,
      );
      expect(
        ClinicWorkflowSettingsMapper.fromJson({'schemaVersion': 99})
            .slotDurationMinutes,
        30,
      );
      expect(
        ClinicWorkflowSettingsMapper.fromJson({'bad': true}).slotDurationMinutes,
        30,
      );
    });

    test('invalid slotDuration falls back to 30', () {
      final settings = ClinicWorkflowSettingsMapper.fromJson({
        'schemaVersion': 1,
        'slotDurationMinutes': 25,
        'lunchBreak': {'enabled': false, 'start': '12:00', 'end': '13:00'},
        'weekdays': [],
        'closedDates': [],
      });
      expect(settings.slotDurationMinutes, 30);
    });

    test('valid slot durations are preserved', () {
      for (final minutes in [15, 20, 45, 60]) {
        final settings = ClinicWorkflowSettingsMapper.fromJson({
          'schemaVersion': 1,
          'slotDurationMinutes': minutes,
          'lunchBreak': {'enabled': false, 'start': '12:00', 'end': '13:00'},
          'weekdays': ClinicWorkflowSettingsMapper.toJson(
            ClinicWorkflowSettings.defaultClinic(),
          )['weekdays'],
          'closedDates': [],
        });
        expect(settings.slotDurationMinutes, minutes);
      }
    });

    test('lunchBreak enabled splits weekday into two intervals', () {
      final settings = ClinicWorkflowSettings.defaultClinic();
      final intervals = ClinicWorkflowSettingsMapper.intervalsForWeekday(
        settings,
        1,
      );
      expect(intervals.length, 2);
      expect(intervals.first.start, const TimeOfDay(hour: 9, minute: 0));
      expect(intervals.first.end, const TimeOfDay(hour: 12, minute: 30));
      expect(intervals.last.start, const TimeOfDay(hour: 13, minute: 30));
      expect(intervals.last.end, const TimeOfDay(hour: 17, minute: 0));
    });

    test('lunchBreak disabled uses single interval', () {
      final base = ClinicWorkflowSettings.defaultClinic();
      final settings = ClinicWorkflowSettings(
        slotDurationMinutes: base.slotDurationMinutes,
        lunchBreak: base.lunchBreak.copyWith(enabled: false),
        weekdays: base.weekdays,
      );
      final intervals = ClinicWorkflowSettingsMapper.intervalsForWeekday(
        settings,
        1,
      );
      expect(intervals.length, 1);
      expect(intervals.first.start, const TimeOfDay(hour: 9, minute: 0));
      expect(intervals.first.end, const TimeOfDay(hour: 17, minute: 0));
    });

    test('closedDates parse date-only and ignore invalid', () {
      final settings = ClinicWorkflowSettingsMapper.fromJson({
        'schemaVersion': 1,
        'slotDurationMinutes': 30,
        'lunchBreak': {'enabled': false, 'start': '12:00', 'end': '13:00'},
        'weekdays': ClinicWorkflowSettingsMapper.toJson(
          ClinicWorkflowSettings.defaultClinic(),
        )['weekdays'],
        'closedDates': ['2026-01-01', 'not-a-date', '2026-12-31'],
      });
      expect(settings.closedDates.length, 2);
      expect(settings.closedDates.first, DateTime(2026, 1, 1));
    });

    test('invalid weekday range disables day', () {
      final settings = ClinicWorkflowSettingsMapper.fromJson({
        'schemaVersion': 1,
        'slotDurationMinutes': 30,
        'lunchBreak': {'enabled': false, 'start': '12:00', 'end': '13:00'},
        'weekdays': [
          {
            'weekday': 1,
            'enabled': true,
            'start': '17:00',
            'end': '09:00',
          },
        ],
        'closedDates': [],
      });
      final monday = settings.weekdaySettings(1)!;
      expect(monday.enabled, isFalse);
    });

    test('toScheduleConfigForDay applies custom slot and closed date', () {
      final closed = DateTime(2026, 5, 25);
      final settings = ClinicWorkflowSettings(
        slotDurationMinutes: 15,
        lunchBreak: ClinicWorkflowSettings.defaultClinic().lunchBreak.copyWith(
              enabled: false,
            ),
        weekdays: ClinicWorkflowSettings.defaultClinic().weekdays,
        closedDates: [closed],
      );
      final cfg = ClinicWorkflowSettingsMapper.toScheduleConfigForDay(
        settings,
        closed,
      );
      expect(cfg.slotDurationMinutes, 15);
      expect(cfg.isClosedDate(closed), isTrue);
    });

    test('round-trip JSON preserves schema', () {
      final original = ClinicWorkflowSettings(
        slotDurationMinutes: 45,
        lunchBreak: const ClinicLunchBreakSettings(
          enabled: true,
          start: TimeOfDay(hour: 12, minute: 0),
          end: TimeOfDay(hour: 12, minute: 45),
        ),
        weekdays: ClinicWorkflowSettings.defaultClinic().weekdays,
        closedDates: [DateTime(2026, 1, 1)],
      );
      final json = ClinicWorkflowSettingsMapper.toJson(original);
      final parsed = ClinicWorkflowSettingsMapper.fromJson(json);
      expect(parsed.slotDurationMinutes, 45);
      expect(parsed.closedDates.single, DateTime(2026, 1, 1));
    });

    test('default clinic schedule config matches mapper monday intervals', () {
      final settings = ClinicWorkflowSettings.defaultClinic();
      final fromMapper = ClinicWorkflowSettingsMapper.toScheduleConfigForDay(
        settings,
        DateTime(2026, 5, 25),
      );
      final defaultCfg = ClinicScheduleConfig.defaultClinic();
      expect(fromMapper.workIntervals.length, defaultCfg.workIntervals.length);
      expect(fromMapper.slotDurationMinutes, defaultCfg.slotDurationMinutes);
    });
  });
}
