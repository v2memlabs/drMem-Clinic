import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/session/mock_tenant_context_bridge.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';

void main() {
  const stagingTenantId = 'a0000001-0001-4001-8001-000000000001';

  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('supabase modda setUser mock tenant id ile ezmez', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;

    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: stagingTenantId, name: 'Klinik A'),
        membership: const Membership(
          id: 'm-1',
          tenantId: stagingTenantId,
          userId: 'profile-1',
          role: AppRoles.doctor,
        ),
        profile: const UserProfile(userId: 'profile-1', displayName: 'Dr. A'),
      ),
    );

    AuthSession.setUser(
      AppUser(
        id: 'profile-1',
        username: 'doctor-a@example.test',
        displayName: 'Dr. A',
        role: AppRoles.doctor,
      ),
    );

    expect(ActiveTenantContextStore.current?.tenantId, stagingTenantId);
    expect(
      ActiveTenantContextStore.current?.tenantId,
      isNot(MockTenantContextBridge.demoTenantId),
    );
  });

  test('mock modda setUser demo tenant bağlar', () {
    AppBackendConfig.activeBackend = DataBackend.mock;

    AuthSession.setUser(
      AppUser(
        id: 'u-1',
        username: 'demo',
        displayName: 'Demo',
        role: AppRoles.doctor,
      ),
    );

    expect(
      ActiveTenantContextStore.current?.tenantId,
      MockTenantContextBridge.demoTenantId,
    );
  });
}
