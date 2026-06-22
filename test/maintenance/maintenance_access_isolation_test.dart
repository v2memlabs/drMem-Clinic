import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/session_bootstrap.dart';
import 'package:v2mem_clinic/core/config/app_env_config.dart';
import 'package:v2mem_clinic/core/config/maintenance_config.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/router/auth_route_guard.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/session/auth_session_bridge.dart';
import 'package:v2mem_clinic/core/session/session_persona.dart';
import 'package:v2mem_clinic/core/session/session_readiness.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSessionBridge.clear();
    SessionReadiness.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
    AppEnvConfig.environment = AppEnvironment.production;
    AppMaintenanceConfig.maintenanceModeEnabled = false;
  });

  group('maintenance-only bootstrap', () {
    test('maintenance operator session is ready without tenant context', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AppEnvConfig.environment = AppEnvironment.staging;
      AppMaintenanceConfig.maintenanceModeEnabled = true;

      final context = SessionBootstrapContext.maintenanceOperator(
        profile: const AuthenticatedProfile(
          profileId: 'op-1',
          displayName: 'IT Op',
          email: 'it@example.com',
          maintenanceOperator: true,
        ),
      );

      SessionReadiness.markBootstrapResult(
        SessionBootstrapResult.maintenanceReady(context),
      );

      final result = AuthSessionBridge.setFromMaintenanceBootstrap(context);
      expect(result.success, isTrue);
      expect(AuthSession.isMaintenanceOperator, isTrue);
      expect(AuthSession.persona, SessionPersona.maintenanceOperator);
      expect(ActiveTenantContextStore.current, isNull);
      expect(SessionReadiness.isReady, isTrue);
    });
  });

  group('login redirect', () {
    test('maintenance-only user redirects to /maintenance', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AppEnvConfig.environment = AppEnvironment.staging;
      AppMaintenanceConfig.maintenanceModeEnabled = true;

      AuthSession.setMaintenanceUser(
        AppUser(
          id: 'op-1',
          username: 'it@example.com',
          displayName: 'IT Op',
          role: AppRoles.maintenanceOperator,
        ),
      );
      SessionReadiness.markBootstrapResult(
        SessionBootstrapResult.maintenanceReady(
          SessionBootstrapContext.maintenanceOperator(
            profile: const AuthenticatedProfile(
              profileId: 'op-1',
              displayName: 'IT Op',
              email: 'it@example.com',
              maintenanceOperator: true,
            ),
          ),
        ),
      );

      expect(AuthSession.dashboardRoute, '/maintenance');
      expect(
        AuthRouteGuard.redirectForLocation('/login'),
        '/maintenance',
      );
    });

    test('normal doctor redirects to /doctor', () {
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc@test.com',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      SessionReadiness.markBootstrapResult(
        SessionBootstrapResult.ready(
          SessionBootstrapContext(
            profile: const AuthenticatedProfile(
              profileId: 'd1',
              displayName: 'Doc',
            ),
            memberships: const [],
            activeTenantId: 't1',
            activeFlutterRole: AppRoles.doctor,
          ),
        ),
      );

      expect(AuthSession.dashboardRoute, '/doctor');
    });

    test('maintenance-only blocked when maintenance mode off', () {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AppEnvConfig.environment = AppEnvironment.staging;
      AppMaintenanceConfig.maintenanceModeEnabled = false;

      AuthSession.setMaintenanceUser(
        AppUser(
          id: 'op-1',
          username: 'it@example.com',
          displayName: 'IT Op',
          role: AppRoles.maintenanceOperator,
        ),
      );
      SessionReadiness.markBootstrapResult(
        SessionBootstrapResult.maintenanceAccessUnavailable(),
      );

      expect(SessionReadiness.phase.name, 'accountBlocked');
    });
  });

  group('route isolation', () {
    setUp(() {
      AppBackendConfig.activeBackend = DataBackend.supabase;
      AppEnvConfig.environment = AppEnvironment.staging;
      AppMaintenanceConfig.maintenanceModeEnabled = true;

      AuthSession.setMaintenanceUser(
        AppUser(
          id: 'op-1',
          username: 'it@example.com',
          displayName: 'IT Op',
          role: AppRoles.maintenanceOperator,
        ),
      );
      SessionReadiness.markBootstrapResult(
        SessionBootstrapResult.maintenanceReady(
          SessionBootstrapContext.maintenanceOperator(
            profile: const AuthenticatedProfile(
              profileId: 'op-1',
              displayName: 'IT Op',
              maintenanceOperator: true,
            ),
          ),
        ),
      );
    });

    test('clinical routes redirect to /maintenance', () {
      for (final path in [
        '/patients',
        '/appointments',
        '/clinical-records',
        '/pdf-outputs',
        '/payments',
        '/consents',
        '/inventory',
        '/physiotherapy/sessions',
        '/settings',
        '/doctor',
      ]) {
        expect(
          AuthRouteGuard.redirectForLocation(path),
          '/maintenance',
          reason: path,
        );
      }
    });

    test('/maintenance routes allowed', () {
      expect(AuthRouteGuard.redirectForLocation('/maintenance'), isNull);
      expect(
        AuthRouteGuard.redirectForLocation('/maintenance/diagnostics'),
        isNull,
      );
    });
  });

  group('clinical user maintenance deny', () {
    test('doctor on /maintenance redirects to dashboard', () {
      AuthSession.setUser(
        AppUser(
          id: 'd1',
          username: 'doc@test.com',
          displayName: 'Doc',
          role: AppRoles.doctor,
        ),
      );
      SessionReadiness.markBootstrapResult(
        SessionBootstrapResult.ready(
          SessionBootstrapContext(
            profile: const AuthenticatedProfile(profileId: 'd1', displayName: 'Doc'),
            memberships: const [],
            activeTenantId: 't1',
            activeFlutterRole: AppRoles.doctor,
          ),
        ),
      );

      expect(
        AuthRouteGuard.redirectForLocation('/maintenance'),
        '/doctor',
      );
    });
  });
}
