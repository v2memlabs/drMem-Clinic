import '../../core/data/backend_config.dart';
import '../../core/config/supabase_env_config.dart';
import '../../core/session/active_tenant_context_store.dart';
import '../../core/settings/app_settings_controller.dart';

/// Demo ayarları için kullanıcı dostu backend/sistem etiketleri (teknik ID yok).
abstract final class SettingsBackendLabels {
  static String get backendModeLabel {
    if (AppBackendConfig.isSupabase) return 'Uzak veritabanı';
    if (AppBackendConfig.isSupabaseRequestedButNotConfigured) {
      return 'Demo / yerel veri modu';
    }
    return 'Mock';
  }

  static String get systemStatusLabel {
    if (AppBackendConfig.isSupabase && SupabaseEnvConfig.isSupabaseConfigured) {
      return 'Bağlı';
    }
    if (AppBackendConfig.isSupabaseRequestedButNotConfigured) {
      return 'Yapılandırılmadı';
    }
    return 'Demo (mock)';
  }

  static String get activeClinicDisplayName {
    final tenantName = ActiveTenantContextStore.current?.tenant.name;
    if (tenantName != null && tenantName.trim().isNotEmpty) {
      return tenantName.trim();
    }
    final clinic = appSettingsController.settings.clinicName.trim();
    if (clinic.isNotEmpty) return clinic;
    return '—';
  }
}
