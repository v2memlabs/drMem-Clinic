import '../data/backend_config.dart';
import '../data/data_backend.dart';
import 'app_env_config.dart';
import 'maintenance_config.dart';
import 'supabase_env_config.dart';

/// Derleme zamanı `--dart-define` sonrası runtime JSON override (debug asset).
abstract final class EnvRuntimeOverrides {
  static void applyFromMap(Map<String, dynamic> raw) {
    SupabaseEnvConfig.applyOverrides(raw);
    AppEnvConfig.applyOverrides(raw);
    AppMaintenanceConfig.applyOverrides(raw);
    AppBackendConfig.applyRuntimeBackendOverride(raw);
    AppBackendConfig.applyEnvironment();
  }

  /// Dart-define yokken debug staging asset'i denenebilir mi?
  static bool get needsDebugAssetFallback =>
      !SupabaseEnvConfig.isSupabaseConfigured &&
      AppBackendConfig.activeBackend == DataBackend.mock;
}
