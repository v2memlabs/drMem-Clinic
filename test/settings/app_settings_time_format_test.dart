import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/settings/app_settings.dart';

void main() {
  group('AppSettings time formatting', () {
    final afternoon = DateTime(2026, 5, 20, 14, 32);
    final morning = DateTime(2026, 5, 20, 9, 5);
    final noon = DateTime(2026, 5, 20, 12, 0);
    final midnight = DateTime(2026, 5, 20, 0, 30);

    test('formatTimePart hour24', () {
      expect(
        AppSettings.formatTimePart(afternoon, TimeFormatKind.hour24),
        '14:32',
      );
      expect(
        AppSettings.formatTimePart(morning, TimeFormatKind.hour24),
        '09:05',
      );
    });

    test('formatTimePart hour12', () {
      expect(
        AppSettings.formatTimePart(afternoon, TimeFormatKind.hour12),
        '2:32 PM',
      );
      expect(
        AppSettings.formatTimePart(morning, TimeFormatKind.hour12),
        '9:05 AM',
      );
      expect(
        AppSettings.formatTimePart(noon, TimeFormatKind.hour12),
        '12:00 PM',
      );
      expect(
        AppSettings.formatTimePart(midnight, TimeFormatKind.hour12),
        '12:30 AM',
      );
    });

    test('formatDateTime respects time format', () {
      expect(
        AppSettings.formatDateTime(
          afternoon,
          DateTimeFormatKind.shortTurkish,
          timeFormat: TimeFormatKind.hour12,
        ),
        '20.05.2026 · 2:32 PM',
      );
    });

    test('formatTimeOfDay', () {
      expect(
        AppSettings.formatTimeOfDay(
          const TimeOfDay(hour: 14, minute: 32),
          TimeFormatKind.hour24,
        ),
        '14:32',
      );
    });
  });
}
