import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/app_user.dart';
import '../config/maintenance_config.dart';
import 'active_tenant_selector.dart';
import 'membership_loader.dart';
import 'session_bootstrap.dart';
import 'tenant_role_mapper.dart';

/// Supabase — profiles + memberships + tenants remote yükleme.
class SupabaseMembershipLoader implements MembershipLoader {
  const SupabaseMembershipLoader();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<SessionBootstrapResult> loadForAppUser(AppUser user) async {
    return loadForProfileId(user.id);
  }

  @override
  Future<SessionBootstrapResult> loadForProfileId(String profileId) async {
    try {
      final profileRow = await _client
          .from('profiles')
          .select('id, display_name, email, login_username, auth_user_id, maintenance_operator')
          .eq('id', profileId)
          .maybeSingle();

      if (profileRow == null) {
        return SessionBootstrapResult.profileMissing();
      }

      final authUserId = profileRow['auth_user_id'] as String?;
      if (authUserId == null || authUserId.isEmpty) {
        return SessionBootstrapResult.profileMissing();
      }

      return _loadMembershipsForProfile(
        profileId: profileId,
        displayName: (profileRow['display_name'] as String?)?.trim(),
        email: profileRow['email'] as String?,
        loginUsername: profileRow['login_username'] as String?,
        maintenanceOperator: profileRow['maintenance_operator'] == true,
      );
    } on PostgrestException {
      return SessionBootstrapResult.notLoaded();
    } catch (_) {
      return SessionBootstrapResult.notLoaded();
    }
  }

  @override
  Future<SessionBootstrapResult> loadForAuthUserId(String authUserId) async {
    try {
      final profileRow = await _client
          .from('profiles')
          .select('id, display_name, email, login_username, maintenance_operator')
          .eq('auth_user_id', authUserId)
          .maybeSingle();

      if (profileRow == null) {
        return SessionBootstrapResult.profileMissing();
      }

      return _loadMembershipsForProfile(
        profileId: profileRow['id'] as String,
        displayName: (profileRow['display_name'] as String?)?.trim(),
        email: profileRow['email'] as String?,
        loginUsername: profileRow['login_username'] as String?,
        maintenanceOperator: profileRow['maintenance_operator'] == true,
      );
    } on PostgrestException {
      return SessionBootstrapResult.notLoaded();
    } catch (_) {
      return SessionBootstrapResult.notLoaded();
    }
  }

  Future<SessionBootstrapResult> _loadMembershipsForProfile({
    required String profileId,
    String? displayName,
    String? email,
    String? loginUsername,
    bool maintenanceOperator = false,
  }) async {
    final profile = AuthenticatedProfile(
      profileId: profileId,
      displayName: displayName != null && displayName.isNotEmpty
          ? displayName
          : 'Kullanıcı',
      email: email,
      loginUsername: loginUsername,
      maintenanceOperator: maintenanceOperator,
    );

    if (maintenanceOperator) {
      if (!AppMaintenanceConfig.isAvailable) {
        return SessionBootstrapResult.maintenanceAccessUnavailable();
      }
      return SessionBootstrapResult.maintenanceReady(
        SessionBootstrapContext.maintenanceOperator(profile: profile),
      );
    }

    final membershipRows = await _client
        .from('memberships')
        .select('id, tenant_id, role, status, tenants(id, name, specialty, status)')
        .eq('profile_id', profileId);

    final list = membershipRows as List<dynamic>;
    if (list.isEmpty) {
      return SessionBootstrapResult.noMembership();
    }

    final memberships = <AuthenticatedMembership>[];
    for (final row in list) {
      final map = row as Map<String, dynamic>;
      final dbRole = map['role'] as String? ?? '';
      final flutterRole = TenantRoleMapper.toFlutterRole(dbRole);
      if (flutterRole == null) {
        return SessionBootstrapResult.unknownRole();
      }

      final tenantMap = map['tenants'] as Map<String, dynamic>?;
      memberships.add(
        AuthenticatedMembership(
          membershipId: map['id'] as String,
          tenantId: map['tenant_id'] as String,
          tenantName: (tenantMap?['name'] as String?)?.trim() ?? '',
          tenantSpecialty: (tenantMap?['specialty'] as String?)?.trim(),
          dbRole: dbRole,
          flutterRole: flutterRole,
          status: map['status'] as String? ?? 'active',
          tenantStatus: tenantMap?['status'] as String? ?? 'active',
        ),
      );
    }

    return ActiveTenantSelector.resolve(
      profile: profile,
      memberships: memberships,
    );
  }
}
