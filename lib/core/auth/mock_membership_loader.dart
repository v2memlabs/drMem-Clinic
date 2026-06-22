import '../../shared/models/app_user.dart';
import '../session/mock_tenant_context_bridge.dart';
import '../settings/app_settings_controller.dart';
import 'active_tenant_selector.dart';
import 'membership_loader.dart';
import 'session_bootstrap.dart';
import 'tenant_role_mapper.dart';

/// Mock backend — demo profile + tek aktif membership.
class MockMembershipLoader implements MembershipLoader {
  const MockMembershipLoader();

  @override
  Future<SessionBootstrapResult> loadForAppUser(AppUser user) async {
    if (!TenantRoleMapper.isKnownFlutterRole(user.role)) {
      return SessionBootstrapResult.unknownRole();
    }

    final dbRole = TenantRoleMapper.toDbRole(user.role);
    final flutterRole = dbRole != null ? TenantRoleMapper.toFlutterRole(dbRole) : null;
    if (dbRole == null || flutterRole == null) {
      return SessionBootstrapResult.unknownRole();
    }

    final settings = appSettingsController.settings;
    final clinicName = settings.clinicName.trim().isNotEmpty
        ? settings.clinicName.trim()
        : 'Dr. Mehmet Yalçınozan';
    final specialty = settings.specialty.trim().isNotEmpty
        ? settings.specialty.trim()
        : 'Ortopedi ve Travmatoloji Uzmanı';

    final email = user.username.contains('@')
        ? user.username
        : '${user.username}@demo.local';

    final profile = AuthenticatedProfile(
      profileId: user.id,
      displayName: user.displayName,
      email: email,
    );

    final membership = AuthenticatedMembership(
      membershipId: 'membership-${user.id}',
      tenantId: MockTenantContextBridge.demoTenantId,
      tenantName: clinicName,
      tenantSpecialty: specialty,
      dbRole: dbRole,
      flutterRole: flutterRole,
      status: 'active',
      tenantStatus: 'active',
    );

    return ActiveTenantSelector.resolve(
      profile: profile,
      memberships: [membership],
    );
  }

  @override
  Future<SessionBootstrapResult> loadForProfileId(String profileId) async {
    return SessionBootstrapResult.profileMissing();
  }

  @override
  Future<SessionBootstrapResult> loadForAuthUserId(String authUserId) async {
    return SessionBootstrapResult.profileMissing();
  }
}
