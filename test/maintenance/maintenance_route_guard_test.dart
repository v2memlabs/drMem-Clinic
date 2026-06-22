import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/config/app_env_config.dart';
import 'package:v2mem_clinic/core/config/maintenance_config.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/router/maintenance_route_guard.dart';
import 'package:v2mem_clinic/core/session/session_readiness.dart';
import 'package:v2mem_clinic/core/auth/session_bootstrap.dart'
    show AuthenticatedProfile, SessionBootstrapContext, SessionBootstrapResult, SessionBootstrapStatus;
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/session/auth_session_bridge.dart';

void main() {
  tearDown(() {
    AuthSessionBridge.clear();
    SessionReadiness.clear();
    AppBackendConfig.activeBackend = DataBackend.mock;
    AppEnvConfig.environment = AppEnvironment.production;
    AppMaintenanceConfig.maintenanceModeEnabled = false;
    MaintenanceRouteGuard.invalidatePing();
  });

  test('production ortamında route register edilmez', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AppEnvConfig.environment = AppEnvironment.production;
    AppMaintenanceConfig.maintenanceModeEnabled = true;

    expect(MaintenanceRouteGuard.routesShouldRegister, isFalse);
  });

  test('staging + maintenance mode route register edilir', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AppEnvConfig.environment = AppEnvironment.staging;
    AppMaintenanceConfig.maintenanceModeEnabled = true;

    expect(MaintenanceRouteGuard.routesShouldRegister, isTrue);
  });

  test('staging maintenance mode kapalıysa route yok', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AppEnvConfig.environment = AppEnvironment.staging;
    AppMaintenanceConfig.maintenanceModeEnabled = false;

    expect(MaintenanceRouteGuard.routesShouldRegister, isFalse);
  });

  test('mock backend maintenance kapalı', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    AppEnvConfig.environment = AppEnvironment.staging;
    AppMaintenanceConfig.maintenanceModeEnabled = true;

    expect(AppMaintenanceConfig.isAvailable, isFalse);
  });

  test('canAttemptAccess oturum hazır değilse false', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AppEnvConfig.environment = AppEnvironment.staging;
    AppMaintenanceConfig.maintenanceModeEnabled = true;

    expect(MaintenanceRouteGuard.canAttemptAccess, isFalse);
  });

  test('canAttemptAccess giriş + ready ise true', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AppEnvConfig.environment = AppEnvironment.staging;
    AppMaintenanceConfig.maintenanceModeEnabled = true;

    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'op@test.com',
        displayName: 'Op',
        role: AppRoles.doctor,
      ),
    );
    SessionReadiness.markBootstrapResult(
      SessionBootstrapResult.ready(
        SessionBootstrapContext(
          profile: const AuthenticatedProfile(
            profileId: 'p1',
            displayName: 'Op',
            email: 'op@test.com',
          ),
          memberships: const [],
          activeTenantId: 't1',
          activeFlutterRole: AppRoles.doctor,
        ),
      ),
    );

    expect(MaintenanceRouteGuard.canAttemptAccess, isTrue);
  });

  test('maintenance operator maintenanceReady canAttemptAccess true', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    AppEnvConfig.environment = AppEnvironment.staging;
    AppMaintenanceConfig.maintenanceModeEnabled = true;

    AuthSession.setMaintenanceUser(
      AppUser(
        id: 'op-1',
        username: 'it@example.com',
        displayName: 'IT',
        role: AppRoles.maintenanceOperator,
      ),
    );
    SessionReadiness.markBootstrapResult(
      SessionBootstrapResult.maintenanceReady(
        SessionBootstrapContext.maintenanceOperator(
          profile: const AuthenticatedProfile(
            profileId: 'op-1',
            displayName: 'IT',
            email: 'it@example.com',
            maintenanceOperator: true,
          ),
        ),
      ),
    );

    expect(MaintenanceRouteGuard.canAttemptAccess, isTrue);
  });
}
