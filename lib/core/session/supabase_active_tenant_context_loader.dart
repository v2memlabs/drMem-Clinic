import '../../shared/models/app_user.dart';
import '../auth/session_bootstrap.dart';
import '../auth/tenant_role_mapper.dart';
import '../saas/active_tenant_context.dart';
import '../saas/membership.dart';
import '../saas/tenant.dart';
import '../saas/user_profile.dart';
import 'active_tenant_context_loader.dart';
import 'active_tenant_load_result.dart';

/// Supabase bootstrap — tenant adı/branş `tenants` join verisinden.
class SupabaseActiveTenantContextLoader implements ActiveTenantContextLoader {
  const SupabaseActiveTenantContextLoader();

  @override
  ActiveTenantLoadResult loadFromMockUser(AppUser user) {
    return ActiveTenantLoadResult.failure(ActiveTenantLoadFailure.notSupportedInMockMode);
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

    return ActiveTenantLoadResult.loaded(
      ActiveTenantContext(
        tenant: Tenant(
          id: membership.tenantId,
          name: membership.tenantName.trim().isNotEmpty
              ? membership.tenantName.trim()
              : 'Klinik',
          specialty: membership.tenantSpecialty?.trim().isNotEmpty == true
              ? membership.tenantSpecialty!.trim()
              : '',
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
    return null;
  }
}
