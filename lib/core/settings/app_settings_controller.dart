import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/user_display_names.dart';
import '../constants/app_roles.dart';
import '../session/mock_tenant_context_bridge.dart';
import '../../features/settings/data/user_display_preferences_mapper.dart';
import '../../features/settings/models/tenant_preferences.dart';
import '../../features/settings/models/tenant_security_settings.dart';
import '../../features/settings/models/user_display_preferences.dart';
import 'app_settings.dart';

final AppSettingsController appSettingsController = AppSettingsController._();

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();

  static const _keyClinicName = 'settings_clinic_name';
  static const _keySpecialty = 'settings_specialty';
  static const _keyAddress = 'settings_address';
  static const _keyPhone = 'settings_phone';
  static const _keyEmail = 'settings_email';
  static const _keyWebsite = 'settings_website';
  static const _keyDateTimeFormat = 'settings_date_time_format';
  static const _keyTimeFormat = 'settings_time_format';
  static const _keyAutoLockDuration = 'settings_auto_lock_duration';
  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyLanguageCode = 'settings_language_code';
  static const _keyAppointmentReminder = 'settings_appointment_reminder';
  static const _keyControlReminder = 'settings_control_reminder';
  static const _keyRequireConsent = 'settings_require_consent';

  static String _displayNameKey(String role) => 'settings_display_name_$role';
  static String _userDisplayPrefsKey(String userId) =>
      'settings_user_display_$userId';

  AppSettings _settings = AppSettings.defaults();
  SharedPreferences? _prefs;
  final Map<String, String> _roleDisplayNames = {};

  AppSettings get settings => _settings;

  String displayNameForRole(String role) {
    return _roleDisplayNames[role] ?? UserDisplayNames.defaultForRole(role);
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final prefs = _prefs!;
    final defaults = AppSettings.defaults();

    _roleDisplayNames.clear();
    for (final role in AppRoles.all) {
      _roleDisplayNames[role] = prefs.getString(_displayNameKey(role)) ??
          UserDisplayNames.defaultForRole(role);
    }

    _settings = AppSettings(
      clinicName: prefs.getString(_keyClinicName) ?? defaults.clinicName,
      specialty: prefs.getString(_keySpecialty) ?? defaults.specialty,
      address: prefs.getString(_keyAddress) ?? defaults.address,
      phone: prefs.getString(_keyPhone) ?? defaults.phone,
      email: prefs.getString(_keyEmail) ?? defaults.email,
      website: prefs.getString(_keyWebsite) ?? defaults.website,
      dateTimeFormat: DateTimeFormatKind.fromStorage(prefs.getString(_keyDateTimeFormat)),
      timeFormat: TimeFormatKind.fromStorage(prefs.getString(_keyTimeFormat)),
      autoLockDuration: AutoLockDurationKind.fromStorage(prefs.getString(_keyAutoLockDuration)),
      themeMode: AppThemeModeKind.fromStorage(prefs.getString(_keyThemeMode)),
      languageCode: prefs.getString(_keyLanguageCode) ?? defaults.languageCode,
      appointmentReminderEnabled:
          prefs.getBool(_keyAppointmentReminder) ?? defaults.appointmentReminderEnabled,
      controlReminderEnabled: prefs.getBool(_keyControlReminder) ?? defaults.controlReminderEnabled,
      requireConsentBeforeMessaging:
          prefs.getBool(_keyRequireConsent) ?? defaults.requireConsentBeforeMessaging,
    );
    notifyListeners();
  }

  Future<void> saveDisplayNameForRole({
    required String role,
    required String displayName,
  }) async {
    final trimmed = displayName.trim();
    final value = trimmed.isEmpty
        ? UserDisplayNames.defaultForRole(role)
        : trimmed;
    final prefs = await _ensurePrefs();
    await prefs.setString(_displayNameKey(role), value);
    _roleDisplayNames[role] = value;
    notifyListeners();
  }

  Future<void> saveClinicProfile({
    required String clinicName,
    required String specialty,
    required String address,
    required String phone,
    required String email,
    required String website,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_keyClinicName, clinicName);
    await prefs.setString(_keySpecialty, specialty);
    await prefs.setString(_keyAddress, address);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyWebsite, website);

    _settings = _settings.copyWith(
      clinicName: clinicName,
      specialty: specialty,
      address: address,
      phone: phone,
      email: email,
      website: website,
    );
    MockTenantContextBridge.refreshTenantFromSettings();
    notifyListeners();
  }

  /// Tenant `settings_json` güvenlik tercihlerini yerel ayarlara uygular.
  Future<void> applyTenantSecuritySettings(TenantSecuritySettings security) async {
    await saveSecuritySettings(autoLockDuration: security.autoLockDuration);
  }

  /// Tenant `settings_json` veya mock tercihlerinden görünüm tercihlerini uygular.
  Future<void> applyTenantPreferences(TenantPreferences preferences) async {
    await applyUserDisplayPreferences(
      UserDisplayPreferences.fromTenant(preferences),
    );
  }

  Future<UserDisplayPreferences?> loadStoredUserDisplayPreferences(
    String userId,
  ) async {
    final prefs = await _ensurePrefs();
    return UserDisplayPreferencesMapper.fromJsonString(
      prefs.getString(_userDisplayPrefsKey(userId)),
    );
  }

  Future<void> saveUserDisplayPreferences({
    required String userId,
    required UserDisplayPreferences preferences,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _userDisplayPrefsKey(userId),
      UserDisplayPreferencesMapper.toJsonString(preferences),
    );
    await applyUserDisplayPreferences(preferences);
  }

  Future<void> applyUserDisplayPreferences(
    UserDisplayPreferences preferences,
  ) async {
    await saveAppearanceSettings(
      dateTimeFormat: preferences.dateTimeFormat,
      timeFormat: preferences.timeFormat,
      themeMode: preferences.themeMode,
      languageCode: preferences.languageCode,
    );
  }

  Future<void> saveAppearanceSettings({
    required DateTimeFormatKind dateTimeFormat,
    required TimeFormatKind timeFormat,
    required AppThemeModeKind themeMode,
    required String languageCode,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_keyDateTimeFormat, dateTimeFormat.name);
    await prefs.setString(_keyTimeFormat, timeFormat.name);
    await prefs.setString(_keyThemeMode, themeMode.name);
    await prefs.setString(_keyLanguageCode, languageCode);

    _settings = _settings.copyWith(
      dateTimeFormat: dateTimeFormat,
      timeFormat: timeFormat,
      themeMode: themeMode,
      languageCode: languageCode,
    );
    notifyListeners();
  }

  Future<void> saveSecuritySettings({
    required AutoLockDurationKind autoLockDuration,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_keyAutoLockDuration, autoLockDuration.name);

    _settings = _settings.copyWith(autoLockDuration: autoLockDuration);
    notifyListeners();
  }

  Future<void> saveMessagingSettings({
    required bool appointmentReminderEnabled,
    required bool controlReminderEnabled,
    required bool requireConsentBeforeMessaging,
  }) async {
    final prefs = await _ensurePrefs();
    await prefs.setBool(_keyAppointmentReminder, appointmentReminderEnabled);
    await prefs.setBool(_keyControlReminder, controlReminderEnabled);
    await prefs.setBool(_keyRequireConsent, requireConsentBeforeMessaging);

    _settings = _settings.copyWith(
      appointmentReminderEnabled: appointmentReminderEnabled,
      controlReminderEnabled: controlReminderEnabled,
      requireConsentBeforeMessaging: requireConsentBeforeMessaging,
    );
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_keyClinicName);
    await prefs.remove(_keySpecialty);
    await prefs.remove(_keyAddress);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyWebsite);
    await prefs.remove(_keyDateTimeFormat);
    await prefs.remove(_keyTimeFormat);
    await prefs.remove(_keyAutoLockDuration);
    await prefs.remove(_keyThemeMode);
    await prefs.remove(_keyLanguageCode);
    await prefs.remove(_keyAppointmentReminder);
    await prefs.remove(_keyControlReminder);
    await prefs.remove(_keyRequireConsent);
    for (final role in AppRoles.all) {
      await prefs.remove(_displayNameKey(role));
    }

    _roleDisplayNames.clear();
    for (final role in AppRoles.all) {
      _roleDisplayNames[role] = UserDisplayNames.defaultForRole(role);
    }
    _settings = AppSettings.defaults();
    notifyListeners();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }
}
