import 'dart:convert';

import '../../../core/settings/app_settings.dart';
import '../models/user_display_preferences.dart';

/// `profiles.preferences_json` içindeki `display` bloğu.
abstract final class UserDisplayPreferencesMapper {
  static const String displayKey = 'display';

  static UserDisplayPreferences? fromProfilePreferencesJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null || json.isEmpty) return null;
    final display = json[displayKey];
    if (display is! Map) return null;
    final map = display is Map<String, dynamic>
        ? display
        : Map<String, dynamic>.from(display);

    final formatRaw = map['date_time_format'];
    final timeFormatRaw = map['time_format'];
    final themeRaw = map['theme_mode'];
    final languageRaw = map['language_code'];

    if (formatRaw is! String &&
        timeFormatRaw is! String &&
        themeRaw is! String &&
        languageRaw is! String) {
      return null;
    }

    return UserDisplayPreferences(
      dateTimeFormat: formatRaw is String
          ? DateTimeFormatKind.fromStorage(formatRaw)
          : UserDisplayPreferences.defaults.dateTimeFormat,
      timeFormat: timeFormatRaw is String
          ? TimeFormatKind.fromStorage(timeFormatRaw)
          : UserDisplayPreferences.defaults.timeFormat,
      themeMode: themeRaw is String
          ? AppThemeModeKind.fromStorage(themeRaw)
          : UserDisplayPreferences.defaults.themeMode,
      languageCode: languageRaw is String && languageRaw.trim().isNotEmpty
          ? languageRaw.trim()
          : UserDisplayPreferences.defaults.languageCode,
    );
  }

  static Map<String, dynamic> mergeIntoProfilePreferences(
    Map<String, dynamic>? existing,
    UserDisplayPreferences preferences,
  ) {
    final next = <String, dynamic>{};
    if (existing != null) {
      next.addAll(Map<String, dynamic>.from(existing));
    }
    next[displayKey] = {
      'date_time_format': preferences.dateTimeFormat.name,
      'time_format': preferences.timeFormat.name,
      'theme_mode': preferences.themeMode.name,
      'language_code': preferences.languageCode,
    };
    return next;
  }

  static UserDisplayPreferences? fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return fromProfilePreferencesJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static String toJsonString(UserDisplayPreferences preferences) {
    return jsonEncode(mergeIntoProfilePreferences(null, preferences));
  }
}
