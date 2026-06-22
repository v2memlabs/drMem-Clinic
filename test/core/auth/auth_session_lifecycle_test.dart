import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/mock_auth_repository_adapter.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
  });

  test('explicit logout clears local session via central termination', () async {
    AuthSession.setUser(
      AppUser(
        id: 'p1',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 't1', name: 'Eski Klinik'),
        membership: const Membership(
          id: 'm1',
          tenantId: 't1',
          userId: 'p1',
          role: AppRoles.doctor,
        ),
        profile: const UserProfile(userId: 'p1', displayName: 'Doktor'),
      ),
    );

    await MockAuthRepositoryAdapter().signOutAsync();

    expect(AuthSession.isLoggedIn, isFalse);
    expect(ActiveTenantContextStore.current, isNull);
  });
}
