import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_password_paths.dart';
import '../auth/supabase_web_auth_callback_uri.dart';
import '../auth/auth_password_paths.dart';
import '../auth/must_change_password_gate.dart';
import '../auth/invitation_deep_link.dart';
import '../auth/auth_session.dart';
import '../auth/session_bootstrap.dart';
import '../config/maintenance_config.dart';
import '../data/backend_config.dart';
import '../session/account_access_reason.dart';
import '../session/session_guard_phase.dart';
import '../session/session_readiness.dart';
import 'maintenance_route_guard.dart';

/// Global redirect — mock davranışı korunur; Supabase fazında genişler.
abstract final class AuthRouteGuard {
  static const String loginPath = '/login';
  static const String initializingPath = '/session/initializing';
  static const String accountNoAccessPath = '/account/no-access';
  static const String maintenancePath = '/maintenance';

  static bool get isSessionReady => SessionReadiness.isReady;

  static SessionGuardPhase get phase => SessionReadiness.phase;

  static String? redirectFor(GoRouterState state) {
    return redirectForLocation(
      state.matchedLocation,
      fullLocation: state.location,
    );
  }

  /// Test ve doğrudan path kontrolü için.
  @visibleForTesting
  static String? redirectForLocation(
    String location, {
    String? fullLocation,
  }) {
    final webRecoveryTarget = _webPasswordRecoveryRouteTarget(location);
    if (webRecoveryTarget != null) return webRecoveryTarget;

    final path = Uri.parse(location).path;
    final onLogin = location == loginPath;
    final onInitializing = location == initializingPath;
    final onNoAccess = location == accountNoAccessPath;
    final onMaintenance = path == maintenancePath || path.startsWith('$maintenancePath/');

    switch (phase) {
      case SessionGuardPhase.unauthenticated:
        if (InvitationDeepLink.isAcceptPath(location)) return null;
        if (AuthPasswordPaths.isPublicPasswordPath(location)) return null;
        return onLogin ? null : loginPath;

      case SessionGuardPhase.initializing:
        if (onInitializing) return null;
        return initializingPath;

      case SessionGuardPhase.accountBlocked:
        if (AppBackendConfig.isMock) {
          return _authenticatedRedirect(location, onLogin, path, onMaintenance);
        }
        if (onNoAccess) return null;
        return _noAccessPathWithReason(fullLocation ?? location);

      case SessionGuardPhase.authenticated:
        if (AuthSession.isMaintenanceOperator) {
          return _maintenanceOperatorRedirect(
            location: location,
            path: path,
            onLogin: onLogin,
            onInitializing: onInitializing,
            onNoAccess: onNoAccess,
            onMaintenance: onMaintenance,
          );
        }

        if (onMaintenance) {
          return AuthSession.dashboardRoute;
        }

        return _authenticatedRedirect(location, onLogin, path, onMaintenance);
    }
  }

  static String? _maintenanceOperatorRedirect({
    required String location,
    required String path,
    required bool onLogin,
    required bool onInitializing,
    required bool onNoAccess,
    required bool onMaintenance,
  }) {
    if (!AppMaintenanceConfig.isAvailable) {
      if (onNoAccess) return null;
      return '$accountNoAccessPath?reason=maintenanceAccessUnavailable';
    }

    if (onMaintenance) return null;

    if (onLogin || onInitializing || onNoAccess || _isClinicalPath(path)) {
      return maintenancePath;
    }

    return maintenancePath;
  }

  static bool _isClinicalPath(String path) {
    if (path == maintenancePath || path.startsWith('$maintenancePath/')) {
      return false;
    }
    if (path == loginPath ||
        path.startsWith('/session/') ||
        path.startsWith('/account/')) {
      return false;
    }
    return true;
  }

  /// Hash router `/login` gösterirken pathname hâlâ `/auth/update-password?code=…` olabilir.
  static String? _webPasswordRecoveryRouteTarget(String location) {
    if (!kIsWeb || !SupabaseWebAuthCallbackUri.isPasswordRecoveryLanding()) {
      return null;
    }
    final browserUri = SupabaseWebAuthCallbackUri.fromBrowser();
    final target = browserUri.hasQuery
        ? '${AuthPasswordPaths.updatePasswordPath}?${browserUri.query}'
        : AuthPasswordPaths.updatePasswordPath;
    if (location == target || AuthPasswordPaths.isUpdatePasswordPath(location)) {
      return null;
    }
    return target;
  }

  static String? _authenticatedRedirect(
    String location,
    bool onLogin,
    String path,
    bool onMaintenance,
  ) {
    if (InvitationDeepLink.isAcceptPath(location)) return null;
    if (AuthPasswordPaths.isPublicPasswordPath(location)) return null;

    if (MustChangePasswordGate.isRequired &&
        !AuthPasswordPaths.isUpdatePasswordPath(location)) {
      return AuthPasswordPaths.updatePasswordPath;
    }

    if (onLogin) return AuthSession.dashboardRoute;
    if (location == initializingPath || location == accountNoAccessPath) {
      return AuthSession.dashboardRoute;
    }
    if (onMaintenance) return AuthSession.dashboardRoute;
    return null;
  }

  static String _noAccessPathWithReason(String location) {
    final status = SessionReadiness.bootstrapStatus;
    if (status != null &&
        status != SessionBootstrapStatus.ready &&
        status != SessionBootstrapStatus.maintenanceReady) {
      final reason = AccountAccessReasonParsing.fromBootstrapStatus(status);
      return '$accountNoAccessPath?reason=${reason.queryValue}';
    }
    final q = Uri.parse(location).queryParameters['reason'];
    if (q != null && q.isNotEmpty) {
      return '$accountNoAccessPath?reason=$q';
    }
    return accountNoAccessPath;
  }
}

