import '../auth/auth_session.dart';
import '../config/maintenance_config.dart';
import '../session/session_readiness.dart';
import '../../features/maintenance/data/maintenance_repository.dart';

/// Maintenance route erişim — env + ping + operator gate.
abstract final class MaintenanceRouteGuard {
  static bool? _pingOk;
  static DateTime? _pingCheckedAt;
  static const Duration _pingTtl = Duration(minutes: 5);

  static bool get routesShouldRegister => AppMaintenanceConfig.isAvailable;

  static bool get canAttemptAccess =>
      AppMaintenanceConfig.isAvailable &&
      AuthSession.isLoggedIn &&
      SessionReadiness.isReady;

  static void invalidatePing() {
    _pingOk = null;
    _pingCheckedAt = null;
  }

  static Future<bool> verifyOperatorAccess(MaintenanceRepository repository) async {
    if (!canAttemptAccess) return false;

    final now = DateTime.now();
    if (_pingOk == true &&
        _pingCheckedAt != null &&
        now.difference(_pingCheckedAt!) < _pingTtl) {
      return true;
    }

    try {
      final result = await repository.ping();
      _pingOk = result.ok;
      _pingCheckedAt = now;
      return result.ok;
    } catch (_) {
      _pingOk = false;
      _pingCheckedAt = now;
      return false;
    }
  }
}
