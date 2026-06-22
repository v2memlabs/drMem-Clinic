import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/config/app_env_config.dart';
import 'package:v2mem_clinic/core/config/env_runtime_overrides.dart';
import 'package:v2mem_clinic/core/config/maintenance_config.dart';
import 'package:v2mem_clinic/core/config/supabase_env_config.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';

void main() {
  setUp(() {
    SupabaseEnvConfig.supabaseUrl = '';
    SupabaseEnvConfig.supabaseAnonKey = '';
    AppBackendConfig.requestedBackend = DataBackend.mock;
    AppBackendConfig.activeBackend = DataBackend.mock;
    AppEnvConfig.environment = AppEnvironment.production;
    AppMaintenanceConfig.maintenanceModeEnabled = false;
  });

  test('applyFromMap fills supabase and staging flags when defines empty', () {
    EnvRuntimeOverrides.applyFromMap({
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'anon-key',
      'DATA_BACKEND': 'supabase',
      'APP_ENV': 'staging',
      'MAINTENANCE_MODE': 'true',
    });

    expect(SupabaseEnvConfig.supabaseUrl, 'https://example.supabase.co');
    expect(SupabaseEnvConfig.supabaseAnonKey, 'anon-key');
    expect(AppBackendConfig.requestedBackend, DataBackend.supabase);
    expect(AppBackendConfig.activeBackend, DataBackend.supabase);
    expect(AppEnvConfig.isStaging, isTrue);
    expect(AppMaintenanceConfig.maintenanceModeEnabled, isTrue);
  });
}
