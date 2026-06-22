import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/settings/app_settings.dart';
import 'package:v2mem_clinic/features/settings/data/user_display_preferences_mapper.dart';
import 'package:v2mem_clinic/features/settings/models/user_display_preferences.dart';

void main() {
  group('UserDisplayPreferencesMapper', () {
    test('round trip display block', () {
      const prefs = UserDisplayPreferences(
        dateTimeFormat: DateTimeFormatKind.iso,
        timeFormat: TimeFormatKind.hour12,
        themeMode: AppThemeModeKind.dark,
        languageCode: 'en',
      );

      final merged =
          UserDisplayPreferencesMapper.mergeIntoProfilePreferences(null, prefs);
      final parsed =
          UserDisplayPreferencesMapper.fromProfilePreferencesJson(merged);

      expect(parsed, isNotNull);
      expect(parsed!.dateTimeFormat, DateTimeFormatKind.iso);
      expect(parsed.timeFormat, TimeFormatKind.hour12);
      expect(parsed.themeMode, AppThemeModeKind.dark);
      expect(parsed.languageCode, 'en');
    });

    test('empty json returns null', () {
      expect(
        UserDisplayPreferencesMapper.fromProfilePreferencesJson(null),
        isNull,
      );
      expect(
        UserDisplayPreferencesMapper.fromProfilePreferencesJson({}),
        isNull,
      );
    });
  });
}
