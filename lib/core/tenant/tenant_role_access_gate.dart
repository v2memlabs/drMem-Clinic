import '../../features/settings/models/tenant_role_access_settings.dart';
import '../auth/auth_session.dart';
import '../constants/app_roles.dart';

/// Oturum kapsamında tenant rol erişim matrisi (IT bakım konsolundan yönetilir).
abstract final class TenantRoleAccessGate {
  static TenantRoleAccessSettings _settings = TenantRoleAccessSettings.empty();

  static TenantRoleAccessSettings get settings => _settings;

  static void apply(TenantRoleAccessSettings settings) {
    _settings = settings;
  }

  static void reset() {
    _settings = TenantRoleAccessSettings.empty();
  }

  static bool isAllowed(TenantRoleAccessKey key) {
    if (!AuthSession.isLoggedIn || AuthSession.isMaintenanceOperator) {
      return false;
    }
    final role = AuthSession.currentUser?.role;
    if (role == null || !TenantRoleAccessCatalog.roles.contains(role)) {
      return false;
    }
    return _settings.isAllowed(role, key);
  }
}
