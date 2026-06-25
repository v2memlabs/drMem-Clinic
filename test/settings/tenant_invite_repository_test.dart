import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/auth/tenant_role_mapper.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/features/settings/data/mock_tenant_invite_repository.dart';
import 'package:v2mem_clinic/features/settings/data/mock_tenant_membership_store.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_failure.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_models.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_invite_repository_provider.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_membership_user.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  setUp(() {
    MockTenantMembershipStore.reset();
    TenantInviteRepositoryProvider.testOverride = MockTenantInviteRepository();
    AuthSession.setUser(
      AppUser(
        id: 'profile-doctor',
        username: 'd@test.local',
        displayName: 'Dr. Test',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-1', name: 'Klinik'),
        membership: const Membership(
          id: 'mem-doctor',
          tenantId: 'tenant-1',
          userId: 'profile-doctor',
          role: AppRoles.doctor,
        ),
        profile: const UserProfile(userId: 'profile-doctor', displayName: 'Dr. Test'),
      ),
    );
  });

  tearDown(() {
    TenantInviteRepositoryProvider.testOverride = null;
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
    MockTenantMembershipStore.reset();
  });

  test('mock create user adds active member to shared store', () async {
    final repo = TenantInviteRepositoryProvider.repository;
    final result = await repo.inviteUser(
      const TenantInviteRequest(
        email: 'yeni@ornek.klinik',
        displayName: 'Yeni Kullanıcı',
        loginUsername: 'yenikullanici',
        role: TenantRoleMapper.dbNurse,
        initialPassword: 'Baslangic123',
      ),
    );

    expect(result.status, 'active');
    expect(
      MockTenantMembershipStore.members.any(
        (m) => m.email == 'yeni@ornek.klinik' && m.status == 'active',
      ),
      isTrue,
    );
  });

  test('mock accept activates invited membership', () async {
    MockTenantMembershipStore.members.add(
      const TenantMembershipUser(
        membershipId: 'mem-invited',
        displayName: 'Davetli',
        email: 'davetli@ornek.klinik',
        role: TenantRoleMapper.dbAssistantSecretary,
        status: 'invited',
      ),
    );

    final accept = await TenantInviteRepositoryProvider.repository
        .acceptMyInvitation();

    expect(accept.status, 'active');
    final member = MockTenantMembershipStore.members.firstWhere(
      (m) => m.membershipId == 'mem-invited',
    );
    expect(member.status, 'active');
  });

  test('mock accept with membership id targets specific invite', () async {
    MockTenantMembershipStore.members.addAll(const [
      TenantMembershipUser(
        membershipId: 'mem-invited-a',
        displayName: 'Davetli A',
        email: 'a@ornek.klinik',
        role: TenantRoleMapper.dbNurse,
        status: 'invited',
      ),
      TenantMembershipUser(
        membershipId: 'mem-invited-b',
        displayName: 'Davetli B',
        email: 'b@ornek.klinik',
        role: TenantRoleMapper.dbAssistantSecretary,
        status: 'invited',
      ),
    ]);

    final accept = await TenantInviteRepositoryProvider.repository
        .acceptMyInvitation(membershipId: 'mem-invited-b');

    expect(accept.membershipId, 'mem-invited-b');
    final member = MockTenantMembershipStore.members.firstWhere(
      (m) => m.membershipId == 'mem-invited-b',
    );
    expect(member.status, 'active');
    expect(
      MockTenantMembershipStore.members
          .firstWhere((m) => m.membershipId == 'mem-invited-a')
          .status,
      'invited',
    );
  });

  test('mock resend updates invited membership', () async {
    MockTenantMembershipStore.members.add(
      const TenantMembershipUser(
        membershipId: 'mem-invited',
        displayName: 'Davetli',
        email: 'davetli@ornek.klinik',
        role: TenantRoleMapper.dbAssistantSecretary,
        status: 'invited',
      ),
    );

    final result = await TenantInviteRepositoryProvider.repository
        .resendInvitation('mem-invited');

    expect(result.operationResult, 'resent');
    expect(result.status, 'invited');
    expect(
      MockTenantMembershipStore.lastInvitedAtByMembership['mem-invited'],
      isNotNull,
    );
  });

  test('mock resend rejects non-invited membership', () async {
    MockTenantMembershipStore.members.add(
      const TenantMembershipUser(
        membershipId: 'mem-active',
        displayName: 'Aktif',
        email: 'aktif@ornek.klinik',
        role: TenantRoleMapper.dbNurse,
        status: 'active',
      ),
    );

    expect(
      () => TenantInviteRepositoryProvider.repository
          .resendInvitation('mem-active'),
      throwsA(
        isA<TenantInviteRepositoryException>().having(
          (e) => e.failure,
          'failure',
          TenantInviteFailure.invitationNotPending,
        ),
      ),
    );
  });

  test('mock resend enforces 60s cooldown', () async {
    MockTenantMembershipStore.members.add(
      const TenantMembershipUser(
        membershipId: 'mem-invited',
        displayName: 'Davetli',
        email: 'davetli@ornek.klinik',
        role: TenantRoleMapper.dbAssistantSecretary,
        status: 'invited',
      ),
    );
    MockTenantMembershipStore.markInvited('mem-invited');

    expect(
      () => TenantInviteRepositoryProvider.repository
          .resendInvitation('mem-invited'),
      throwsA(
        isA<TenantInviteRepositoryException>().having(
          (e) => e.failure,
          'failure',
          TenantInviteFailure.inviteRateLimited,
        ),
      ),
    );
  });

  test('mock cancel disables invited membership', () async {
    MockTenantMembershipStore.members.add(
      const TenantMembershipUser(
        membershipId: 'mem-invited',
        displayName: 'Davetli',
        email: 'davetli@ornek.klinik',
        role: TenantRoleMapper.dbAssistantSecretary,
        status: 'invited',
      ),
    );

    final result = await TenantInviteRepositoryProvider.repository
        .cancelInvitation('mem-invited');

    expect(result.status, 'disabled');
    final member = MockTenantMembershipStore.members.firstWhere(
      (m) => m.membershipId == 'mem-invited',
    );
    expect(member.status, 'disabled');
  });

  test('mock cancel rejects active membership', () async {
    MockTenantMembershipStore.members.add(
      const TenantMembershipUser(
        membershipId: 'mem-active',
        displayName: 'Aktif',
        email: 'aktif@ornek.klinik',
        role: TenantRoleMapper.dbNurse,
        status: 'active',
      ),
    );

    expect(
      () => TenantInviteRepositoryProvider.repository
          .cancelInvitation('mem-active'),
      throwsA(
        isA<TenantInviteRepositoryException>().having(
          (e) => e.failure,
          'failure',
          TenantInviteFailure.invitationNotPending,
        ),
      ),
    );
  });
}
