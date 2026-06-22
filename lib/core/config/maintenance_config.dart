import '../data/backend_config.dart';
import 'app_env_config.dart';

/// Maintenance / Bootstrap Console — staging/dev only.
abstract final class AppMaintenanceConfig {
  static bool maintenanceModeEnabled = false;

  static void loadFromEnvironment() {
    maintenanceModeEnabled = const bool.fromEnvironment(
      'MAINTENANCE_MODE',
      defaultValue: false,
    );
  }

  static void applyOverrides(Map<String, dynamic> raw) {
    final value = raw['MAINTENANCE_MODE'];
    if (value is bool) {
      maintenanceModeEnabled = value;
      return;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        maintenanceModeEnabled = true;
      } else if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        maintenanceModeEnabled = false;
      }
    }
  }

  /// Route registration ve maintenance feature gate.
  static bool get isAvailable =>
      AppBackendConfig.isSupabase &&
      AppEnvConfig.isNonProduction &&
      maintenanceModeEnabled;
}
