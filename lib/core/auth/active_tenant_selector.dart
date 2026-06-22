import 'session_bootstrap.dart';
import 'tenant_role_mapper.dart';

/// Profil + membership listesinden active tenant ve bootstrap bağlamı seçer.
abstract final class ActiveTenantSelector {
  /// Tek aktif membership → otomatik active tenant; çoklu → [needsTenantSelection].
  static SessionBootstrapResult resolve({
    required AuthenticatedProfile profile,
    required List<AuthenticatedMembership> memberships,
  }) {
    if (memberships.isEmpty) {
      return SessionBootstrapResult.noMembership();
    }

    for (final m in memberships) {
      if (!TenantRoleMapper.isKnownDbRole(m.dbRole)) {
        return SessionBootstrapResult.unknownRole();
      }
      final mappedFlutter = TenantRoleMapper.toFlutterRole(m.dbRole);
      if (mappedFlutter == null) {
        return SessionBootstrapResult.unknownRole();
      }
    }

    final eligible = memberships
        .where((m) => m.isActive && m.isTenantActive)
        .toList();

    if (eligible.isEmpty) {
      if (memberships.any((m) => !m.isActive)) {
        return SessionBootstrapResult.inactiveMembership();
      }
      if (memberships.any((m) => !m.isTenantActive)) {
        return SessionBootstrapResult.inactiveTenant();
      }
      return SessionBootstrapResult.noMembership();
    }

    if (eligible.length > 1) {
      return SessionBootstrapResult.needsTenantSelection();
    }

    final active = eligible.first;
    final flutterRole = TenantRoleMapper.toFlutterRole(active.dbRole);
    if (flutterRole == null) {
      return SessionBootstrapResult.unknownRole();
    }

    return SessionBootstrapResult.ready(
      SessionBootstrapContext(
        profile: profile,
        memberships: memberships,
        activeTenantId: active.tenantId,
        activeFlutterRole: flutterRole,
      ),
    );
  }
}
