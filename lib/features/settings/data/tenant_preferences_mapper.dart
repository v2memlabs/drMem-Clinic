import '../models/tenant_preferences.dart';
import 'tenant_settings_json_mapper.dart';

abstract final class TenantPreferencesMapper {
  static TenantPreferences fromJson(Map<String, dynamic>? json) {
    return TenantSettingsJsonMapper.preferencesFromJson(json);
  }

  static Map<String, dynamic> toJson(TenantPreferences preferences) {
    return TenantSettingsJsonMapper.preferencesToJson(preferences);
  }
}
