import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/pending_invitation_store.dart';
import 'package:v2mem_clinic/core/auth/session_bootstrap.dart';
import 'package:v2mem_clinic/core/auth/session_termination.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/session/session_readiness.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    SessionReadiness.clear();
    PendingInvitationStore.clear();
  });

  test('signOutRemoteAndLocal clears auth tenant and bootstrap state', () async {
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
    SessionReadiness.markBootstrapResult(
      const SessionBootstrapResult(status: SessionBootstrapStatus.ready),
    );

    await SessionTermination.signOutRemoteAndLocal();

    expect(AuthSession.isLoggedIn, isFalse);
    expect(ActiveTenantContextStore.current, isNull);
    expect(SessionReadiness.bootstrapStatus, isNull);
  });

  test('signOutRemoteAndLocal can preserve pending invitation', () async {
    PendingInvitationStore.setMembershipId('a1b2c3d4-e5f6-4789-a012-3456789abcde');
    await SessionTermination.signOutRemoteAndLocal(clearPendingInvitation: false);
    expect(PendingInvitationStore.membershipId, isNotNull);
  });
}
