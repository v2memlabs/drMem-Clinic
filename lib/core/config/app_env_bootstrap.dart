import '../data/backend_config.dart';
import 'app_env_config.dart';
import 'debug_env_asset_loader.dart';
import 'env_runtime_overrides.dart';
import 'maintenance_config.dart';
import 'supabase_client_initializer.dart';
import 'supabase_env_config.dart';

/// Uygulama açılışında ortam okuma + koşullu Supabase init.
abstract final class AppEnvBootstrap {
  static bool _initialized = false;
  static SupabaseInitResult? lastSupabaseInit;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    SupabaseEnvConfig.loadFromEnvironment();
    AppEnvConfig.loadFromEnvironment();
    AppMaintenanceConfig.loadFromEnvironment();
    AppBackendConfig.applyEnvironment();

    if (EnvRuntimeOverrides.needsDebugAssetFallback) {
      final debugConfig = await DebugEnvAssetLoader.loadStagingConfig();
      if (debugConfig != null) {
        EnvRuntimeOverrides.applyFromMap(debugConfig);
      }
    }

    if (AppBackendConfig.isSupabase && SupabaseEnvConfig.isSupabaseConfigured) {
      lastSupabaseInit = await SupabaseClientInitializer.initializeIfConfigured();
    }

    _initialized = true;
  }
}
