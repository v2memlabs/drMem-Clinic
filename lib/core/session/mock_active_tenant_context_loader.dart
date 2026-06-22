import '../../shared/models/app_user.dart';
import '../auth/session_bootstrap.dart';
import '../auth/tenant_role_mapper.dart';
import '../constants/app_roles.dart';
import '../saas/active_tenant_context.dart';
import '../saas/membership.dart';
import '../saas/tenant.dart';
import '../saas/user_profile.dart';
import '../settings/app_settings_controller.dart';
import 'active_tenant_context_loader.dart';
import 'active_tenant_load_result.dart';
import 'mock_tenant_context_bridge.dart';
import 'mock_profile_ids.dart';

/// Mock backend — mevcut demo tenant davranışı.
class MockActiveTenantContextLoader implements ActiveTenantContextLoader {
  const MockActiveTenantContextLoader();

  @override
  ActiveTenantLoadResult loadFromMockUser(AppUser user) {
    if (!TenantRoleMapper.isKnownFlutterRole(user.role)) {
      return ActiveTenantLoadResult.failure(ActiveTenantLoadFailure.unknownRole);
    }

    final settings = appSettingsController.settings;
    final tenant = Tenant(
      id: MockTenantContextBridge.demoTenantId,
      name: settings.clinicName.trim().isNotEmpty
          ? settings.clinicName.trim()
          : 'Dr. Mehmet Yalçınozan',
      specialty: settings.specialty.trim().isNotEmpty
          ? settings.specialty.trim()
          : 'Ortopedi ve Travmatoloji Uzmanı',
    );

    return ActiveTenantLoadResult.loaded(
      ActiveTenantContext(
        tenant: tenant,
        membership: Membership(
          id: 'membership-${user.id}',
          tenantId: MockTenantContextBridge.demoTenantId,
          userId: user.id,
          role: user.role,
        ),
        profile: UserProfile(
          userId: _mockProfileIdForRole(user.role, user.id),
          displayName: user.displayName,
        ),
      ),
    );
  }

  @override
  ActiveTenantLoadResult loadFromBootstrap(SessionBootstrapContext context) {
    final membership = _activeMembershipFor(context);
    if (membership == null) {
      return ActiveTenantLoadResult.failure(ActiveTenantLoadFailure.membershipNotFound);
    }
    if (!membership.isActive) {
      return ActiveTenantLoadResult.failure(ActiveTenantLoadFailure.inactiveMembership);
    }

    final flutterRole = TenantRoleMapper.toFlutterRole(membership.dbRole);
    if (flutterRole == null) {
      return ActiveTenantLoadResult.failure(ActiveTenantLoadFailure.unknownRole);
    }

    final settings = appSettingsController.settings;
    final specialty = membership.tenantSpecialty?.trim().isNotEmpty == true
        ? membership.tenantSpecialty!.trim()
        : (settings.specialty.trim().isNotEmpty
            ? settings.specialty.trim()
            : 'Ortopedi ve Travmatoloji Uzmanı');

    return ActiveTenantLoadResult.loaded(
      ActiveTenantContext(
        tenant: Tenant(
          id: membership.tenantId,
          name: membership.tenantName.trim().isNotEmpty
              ? membership.tenantName.trim()
              : 'Klinik',
          specialty: specialty,
        ),
        membership: Membership(
          id: membership.membershipId,
          tenantId: membership.tenantId,
          userId: context.profile.profileId,
          role: flutterRole,
          status: membership.status,
        ),
        profile: UserProfile(
          userId: context.profile.profileId,
          displayName: context.profile.displayName,
        ),
      ),
    );
  }

  AuthenticatedMembership? _activeMembershipFor(SessionBootstrapContext context) {
    for (final m in context.memberships) {
      if (m.tenantId == context.activeTenantId) return m;
    }
    return context.memberships.isNotEmpty ? context.memberships.first : null;
  }

  static String _mockProfileIdForRole(String role, String fallbackUserId) {
    switch (role) {
      case AppRoles.doctor:
        return MockProfileIds.primaryDoctor;
      case AppRoles.assistant:
        return MockProfileIds.assistant;
      case AppRoles.physiotherapist:
        return MockProfileIds.physiotherapist;
      case AppRoles.nurse:
        return MockProfileIds.nurse;
      default:
        return fallbackUserId;
    }
  }
}
