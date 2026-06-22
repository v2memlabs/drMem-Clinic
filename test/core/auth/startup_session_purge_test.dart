import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/pending_invitation_store.dart';
import 'package:v2mem_clinic/core/auth/startup_session_purge.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    StartupSessionPurge.resetForTest();
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    PendingInvitationStore.clear();
  });

  test('run clears stale mock session before app render (mock backend)', () async {
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

    final outcome = await StartupSessionPurge.run();

    expect(outcome, StartupSessionPurgeOutcome.notApplicable);
    expect(StartupSessionPurge.isCompleted, isTrue);
    expect(AuthSession.isLoggedIn, isFalse);
    expect(ActiveTenantContextStore.current, isNull);
  });

  test('run preserves pending invitation membership id', () async {
    PendingInvitationStore.setMembershipId('a1b2c3d4-e5f6-4789-a012-3456789abcde');
    await StartupSessionPurge.run();
    expect(PendingInvitationStore.membershipId, isNotNull);
  });
}
