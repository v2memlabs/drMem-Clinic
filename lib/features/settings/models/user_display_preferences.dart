import '../../../core/settings/app_settings.dart';
import 'tenant_preferences.dart';

/// Kullanıcıya özel görünüm tercihleri (`profiles.preferences_json.display`).
class UserDisplayPreferences {
  final DateTimeFormatKind dateTimeFormat;
  final TimeFormatKind timeFormat;
  final AppThemeModeKind themeMode;
  final String languageCode;

  const UserDisplayPreferences({
    required this.dateTimeFormat,
    required this.timeFormat,
    required this.themeMode,
    required this.languageCode,
  });

  static const UserDisplayPreferences defaults = UserDisplayPreferences(
    dateTimeFormat: DateTimeFormatKind.shortTurkish,
    timeFormat: TimeFormatKind.hour24,
    themeMode: AppThemeModeKind.light,
    languageCode: 'tr',
  );

  factory UserDisplayPreferences.fromTenant(TenantPreferences tenant) {
    return UserDisplayPreferences(
      dateTimeFormat: tenant.dateTimeFormat,
      timeFormat: UserDisplayPreferences.defaults.timeFormat,
      themeMode: tenant.themeMode,
      languageCode: tenant.languageCode,
    );
  }

  UserDisplayPreferences copyWith({
    DateTimeFormatKind? dateTimeFormat,
    TimeFormatKind? timeFormat,
    AppThemeModeKind? themeMode,
    String? languageCode,
  }) {
    return UserDisplayPreferences(
      dateTimeFormat: dateTimeFormat ?? this.dateTimeFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
