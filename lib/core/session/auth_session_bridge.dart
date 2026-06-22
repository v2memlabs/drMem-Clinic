import 'dart:async';

import '../../shared/models/app_user.dart';
import '../auth/session_bootstrap.dart';
import '../auth/tenant_role_mapper.dart';
import '../constants/app_roles.dart';
import '../saas/active_tenant_context.dart';
import 'active_tenant_context_store.dart';
import 'active_tenant_context_sync.dart';
import 'active_tenant_load_result.dart';
import '../auth/auth_session.dart';
import '../auth/session_local_cleanup.dart';
import '../data/repository_cache_coordinator.dart';
import '../../features/settings/data/settings_persistence_sync.dart';
import 'mock_active_tenant_context_loader.dart';
import 'session_bridge_result.dart';
import 'session_context_resolver.dart';

/// [AuthSession] + [ActiveTenantContextStore] köprüsü.
///
/// Aktif login: `mockLogin` + [AuthSession.setUser]. Bu sınıf sonraki paketler
/// ve testler için hazır; bootstrap yolu şimdilik üretim akışında değil.
abstract final class AuthSessionBridge {
  /// Mock demo girişi — [AuthSession.setUser] ile aynı (loader üzerinden tenant).
  static void setFromMockUser(AppUser user) {
    final loadResult = const MockActiveTenantContextLoader().loadFromMockUser(user);
    if (!loadResult.success || loadResult.context == null) {
      AuthSession.clear();
      return;
    }
    _applyUserAndContext(user, loadResult.context!);
  }

  /// Bakım operatörü bootstrap — tenant bağlamı yok.
  static SessionBridgeResult setFromMaintenanceBootstrap(
    SessionBootstrapContext context,
  ) {
    if (!context.isMaintenanceOnly && !context.profile.maintenanceOperator) {
      return SessionBridgeResult.failure(SessionBridgeFailure.bootstrapNotReady);
    }

    final user = AppUser(
      id: context.profile.profileId,
      username: context.profile.preferredLoginIdentity,
      displayName: context.profile.displayName,
      role: AppRoles.maintenanceOperator,
    );

    RepositoryCacheCoordinator.onSessionEstablished();
    AuthSession.setMaintenanceUser(user);
    ActiveTenantContextStore.clearSilently();
    return SessionBridgeResult.applied();
  }

  /// Supabase bootstrap sonrası oturum. Bilinmeyen rolde oturum açılmaz.
  static SessionBridgeResult setFromBootstrapContext(SessionBootstrapContext context) {
    final membership = _membershipForActiveTenant(context);
    if (membership == null) {
      return SessionBridgeResult.failure(SessionBridgeFailure.membershipNotFound);
    }
    if (!membership.isActive) {
      return SessionBridgeResult.failure(SessionBridgeFailure.inactiveMembership);
    }
    if (!membership.isTenantActive) {
      return SessionBridgeResult.failure(SessionBridgeFailure.inactiveTenant);
    }

    final mappedRole = TenantRoleMapper.toFlutterRole(membership.dbRole);
    if (mappedRole == null || !TenantRoleMapper.isKnownFlutterRole(mappedRole)) {
      return SessionBridgeResult.failure(SessionBridgeFailure.unknownRole);
    }
    if (mappedRole != context.activeFlutterRole) {
      return SessionBridgeResult.failure(SessionBridgeFailure.roleMismatch);
    }

    final loadResult = SessionContextResolver.tenantLoader.loadFromBootstrap(context);
    if (!loadResult.success || loadResult.context == null) {
      return _mapLoadFailure(loadResult.failure);
    }

    final user = AppUser(
      id: context.profile.profileId,
      username: context.profile.preferredLoginIdentity,
      displayName: context.profile.displayName,
      role: mappedRole,
    );

    _applyUserAndContext(user, loadResult.context!);
    return SessionBridgeResult.applied();
  }

  /// [AuthSession.clear] + aktif tenant store temizliği + provider cache sıfırlama.
  static void clear() {
    SessionLocalCleanup.clearAll();
  }

  static void _applyUserAndContext(AppUser user, ActiveTenantContext tenantContext) {
    RepositoryCacheCoordinator.onSessionEstablished();
    AuthSession.setUser(user);
    ActiveTenantContextStore.set(tenantContext);
    unawaited(ActiveTenantContextSync.syncBestEffort());
    SettingsPersistenceSync.syncAfterSessionEstablished();
  }

  static AuthenticatedMembership? _membershipForActiveTenant(
    SessionBootstrapContext context,
  ) {
    for (final m in context.memberships) {
      if (m.tenantId == context.activeTenantId) return m;
    }
    return null;
  }

  static SessionBridgeResult _mapLoadFailure(ActiveTenantLoadFailure? failure) {
    switch (failure) {
      case ActiveTenantLoadFailure.unknownRole:
        return SessionBridgeResult.failure(SessionBridgeFailure.unknownRole);
      case ActiveTenantLoadFailure.inactiveMembership:
        return SessionBridgeResult.failure(SessionBridgeFailure.inactiveMembership);
      case ActiveTenantLoadFailure.membershipNotFound:
        return SessionBridgeResult.failure(SessionBridgeFailure.membershipNotFound);
      default:
        return SessionBridgeResult.failure(SessionBridgeFailure.tenantLoadFailed);
    }
  }
}
