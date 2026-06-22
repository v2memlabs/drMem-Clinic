import '../auth/session_bootstrap.dart';
import '../data/backend_config.dart';
import '../data/repository_cache_coordinator.dart';
import '../auth/auth_session.dart';
import 'session_guard_phase.dart';

/// Bootstrap / membership durumu — Supabase fazında set edilir; mock’ta kullanılmaz.
abstract final class SessionReadiness {
  static bool isInitializing = false;

  static SessionBootstrapStatus? bootstrapStatus;

  static void markInitializing() {
    isInitializing = true;
    bootstrapStatus = null;
    RepositoryCacheCoordinator.resetAllRemoteProviderCaches();
  }

  static void markBootstrapResult(SessionBootstrapResult result) {
    isInitializing = false;
    bootstrapStatus = result.status;
  }

  static void clear() {
    isInitializing = false;
    bootstrapStatus = null;
  }

  /// Mock: giriş varsa hazır. Supabase: bootstrap [SessionBootstrapStatus.ready] gerekir.
  static bool get isReady {
    if (!AuthSession.isLoggedIn) return false;
    if (AppBackendConfig.isMock) return true;
    if (isInitializing) return false;
    return bootstrapStatus == SessionBootstrapStatus.ready ||
        bootstrapStatus == SessionBootstrapStatus.maintenanceReady;
  }

  static SessionGuardPhase get phase {
    if (!AuthSession.isLoggedIn) {
      return SessionGuardPhase.unauthenticated;
    }

    if (AppBackendConfig.isMock) {
      return SessionGuardPhase.authenticated;
    }

    if (isInitializing) {
      return SessionGuardPhase.initializing;
    }

    final status = bootstrapStatus;
    if (status == null) {
      return SessionGuardPhase.initializing;
    }
    if (status == SessionBootstrapStatus.ready ||
        status == SessionBootstrapStatus.maintenanceReady) {
      return SessionGuardPhase.authenticated;
    }

    switch (status) {
      case SessionBootstrapStatus.maintenanceAccessUnavailable:
      case SessionBootstrapStatus.noMembership:
      case SessionBootstrapStatus.inactiveMembership:
      case SessionBootstrapStatus.inactiveTenant:
      case SessionBootstrapStatus.unknownRole:
      case SessionBootstrapStatus.profileMissing:
      case SessionBootstrapStatus.backendNotConfigured:
      case SessionBootstrapStatus.needsTenantSelection:
      case SessionBootstrapStatus.invitationAcceptFailed:
      case SessionBootstrapStatus.multiplePendingInvitations:
      case SessionBootstrapStatus.notLoaded:
        return SessionGuardPhase.accountBlocked;
      case SessionBootstrapStatus.ready:
      case SessionBootstrapStatus.maintenanceReady:
        return SessionGuardPhase.authenticated;
    }
  }
}
