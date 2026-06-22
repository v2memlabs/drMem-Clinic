import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/core/saas/active_tenant_context.dart';
import 'package:v2mem_clinic/core/saas/membership.dart';
import 'package:v2mem_clinic/core/saas/tenant.dart';
import 'package:v2mem_clinic/core/saas/user_profile.dart';
import 'package:v2mem_clinic/core/session/active_tenant_context_store.dart';
import 'package:v2mem_clinic/core/auth/tenant_role_mapper.dart';
import 'package:v2mem_clinic/features/settings/data/mock_tenant_membership_repository.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_failure.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_membership_repository.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_membership_user.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(() {
    AuthSession.clear();
    ActiveTenantContextStore.clearSilently();
  });

  ActiveTenantContext doctorContext() {
    return ActiveTenantContext(
      tenant: const Tenant(id: 'tenant-1', name: 'Klinik'),
      membership: const Membership(
        id: 'mem-doctor',
        tenantId: 'tenant-1',
        userId: 'profile-doctor',
        role: AppRoles.doctor,
      ),
      profile: const UserProfile(userId: 'profile-doctor', displayName: 'Doktor'),
    );
  }

  test('doctor lists tenant members', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-doctor',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(doctorContext());

    final repo = MockTenantMembershipRepository();
    final members = await repo.listCurrentTenantMembers();

    expect(members.length, 2);
    expect(members.any((m) => m.displayName.contains('Asistan')), isTrue);
  });

  test('assistant cannot list members', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-assistant',
        username: 'a@test.local',
        displayName: 'Asistan',
        role: AppRoles.assistant,
      ),
    );

    final repo = MockTenantMembershipRepository();
    expect(
      () => repo.listCurrentTenantMembers(),
      throwsA(
        isA<TenantMembershipRepositoryException>().having(
          (e) => e.failure,
          'failure',
          TenantMembershipFailure.forbidden,
        ),
      ),
    );
  });

  test('doctor updates assistant role to nurse', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-doctor',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(doctorContext());

    final repo = MockTenantMembershipRepository();
    await repo.updateRole(
      membershipId: 'mem-assistant',
      role: TenantRoleMapper.dbNurse,
    );

    final members = await repo.listCurrentTenantMembers();
    final assistant = members.firstWhere((m) => m.membershipId == 'mem-assistant');
    expect(assistant.role, TenantRoleMapper.dbNurse);
  });

  test('self role update blocked', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-doctor',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(doctorContext());

    final repo = MockTenantMembershipRepository();
    expect(
      () => repo.updateRole(
        membershipId: 'mem-doctor',
        role: TenantRoleMapper.dbAssistantSecretary,
      ),
      throwsA(
        isA<TenantMembershipRepositoryException>().having(
          (e) => e.failure,
          'failure',
          TenantMembershipFailure.selfUpdateBlocked,
        ),
      ),
    );
  });

  test('last active doctor role downgrade blocked', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-doctor-a',
        username: 'a@test.local',
        displayName: 'Doktor A',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-1', name: 'Klinik'),
        membership: const Membership(
          id: 'mem-doctor-a',
          tenantId: 'tenant-1',
          userId: 'profile-doctor-a',
          role: AppRoles.doctor,
        ),
        profile: const UserProfile(userId: 'profile-doctor-a', displayName: 'Doktor A'),
      ),
    );

    final repo = MockTenantMembershipRepository(
      seed: const [
        TenantMembershipUser(
          membershipId: 'mem-doctor-b',
          displayName: 'Tek Aktif Doktor',
          email: 'b@test.local',
          role: TenantRoleMapper.dbDoctorAdmin,
          status: 'active',
        ),
      ],
    );

    expect(
      () => repo.updateRole(
        membershipId: 'mem-doctor-b',
        role: TenantRoleMapper.dbNurse,
      ),
      throwsA(
        isA<TenantMembershipRepositoryException>().having(
          (e) => e.failure,
          'failure',
          TenantMembershipFailure.lastAdminBlocked,
        ),
      ),
    );
  });

  test('last active doctor deactivate blocked for other admin attempt', () async {
    AuthSession.setUser(
      AppUser(
        id: 'profile-doctor',
        username: 'd@test.local',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );
    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: const Tenant(id: 'tenant-1', name: 'Klinik'),
        membership: const Membership(
          id: 'mem-doctor-a',
          tenantId: 'tenant-1',
          userId: 'profile-doctor-a',
          role: AppRoles.doctor,
        ),
        profile: const UserProfile(userId: 'profile-doctor-a', displayName: 'Doktor A'),
      ),
    );

    final repo = MockTenantMembershipRepository(
      seed: const [
        TenantMembershipUser(
          membershipId: 'mem-doctor-a',
          displayName: 'Doktor A',
          email: 'a@test.local',
          role: TenantRoleMapper.dbDoctorAdmin,
          status: 'active',
        ),
        TenantMembershipUser(
          membershipId: 'mem-doctor-b',
          displayName: 'Doktor B',
          email: 'b@test.local',
          role: TenantRoleMapper.dbDoctorAdmin,
          status: 'active',
        ),
      ],
    );

    await repo.updateStatus(
      membershipId: 'mem-doctor-b',
      status: 'disabled',
    );

    final members = await repo.listCurrentTenantMembers();
    final doctorB = members.firstWhere((m) => m.membershipId == 'mem-doctor-b');
    expect(doctorB.status, 'disabled');
  });
}
