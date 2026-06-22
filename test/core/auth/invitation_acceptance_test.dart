import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/active_tenant_selector.dart';
import 'package:v2mem_clinic/core/auth/auth_bootstrap_mapper.dart';
import 'package:v2mem_clinic/core/auth/auth_failure_reason.dart';
import 'package:v2mem_clinic/core/auth/session_bootstrap.dart';
import 'package:v2mem_clinic/core/auth/tenant_role_mapper.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';

void main() {
  group('ActiveTenantSelector invited membership', () {
    const profile = AuthenticatedProfile(
      profileId: 'p1',
      displayName: 'Invitee',
      email: 'invitee@example.test',
    );

    test('invited-only membership → inactiveMembership', () {
      final result = ActiveTenantSelector.resolve(
        profile: profile,
        memberships: [
          AuthenticatedMembership(
            membershipId: 'm1',
            tenantId: 't1',
            tenantName: 'Klinik',
            dbRole: TenantRoleMapper.dbNurse,
            flutterRole: AppRoles.nurse,
            status: 'invited',
            tenantStatus: 'active',
          ),
        ],
      );
      expect(result.status, SessionBootstrapStatus.inactiveMembership);
    });
  });

  group('Auth bootstrap invitation failures', () {
    test('maps invitation accept failure to user message', () {
      expect(
        AuthBootstrapMapper.toFailureReason(
          SessionBootstrapStatus.invitationAcceptFailed,
        ),
        AuthFailureReason.invitationAcceptFailed,
      );
      expect(
        AuthBootstrapMapper.userMessage(
          SessionBootstrapStatus.multiplePendingInvitations,
        ),
        AuthFailureReason.multiplePendingInvitations.message,
      );
    });
  });
}
