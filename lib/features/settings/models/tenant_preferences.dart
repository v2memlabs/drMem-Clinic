import '../../../core/settings/app_settings.dart';

/// Tenant-scoped UI preferences (`tenants.settings_json`).
class TenantPreferences {
  final DateTimeFormatKind dateTimeFormat;
  final String weekStart;
  final String languageCode;
  final AppThemeModeKind themeMode;
  final String currencyCode;

  const TenantPreferences({
    required this.dateTimeFormat,
    this.weekStart = 'monday',
    this.languageCode = 'tr',
    this.themeMode = AppThemeModeKind.light,
    this.currencyCode = 'TRY',
  });

  static const TenantPreferences defaults = TenantPreferences(
    dateTimeFormat: DateTimeFormatKind.shortTurkish,
  );

  TenantPreferences copyWith({
    DateTimeFormatKind? dateTimeFormat,
    String? weekStart,
    String? languageCode,
    AppThemeModeKind? themeMode,
    String? currencyCode,
  }) {
    return TenantPreferences(
      dateTimeFormat: dateTimeFormat ?? this.dateTimeFormat,
      weekStart: weekStart ?? this.weekStart,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}
