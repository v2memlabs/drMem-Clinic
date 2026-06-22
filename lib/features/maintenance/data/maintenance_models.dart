/// Maintenance RPC modelleri — PII minimum; ekranda gösterim operatör içindir.
class MaintenancePingResult {
  final bool ok;
  final String? operatorProfileId;
  final String? error;

  const MaintenancePingResult({
    required this.ok,
    this.operatorProfileId,
    this.error,
  });

  factory MaintenancePingResult.fromJson(Map<String, dynamic> json) {
    return MaintenancePingResult(
      ok: json['ok'] == true,
      operatorProfileId: json['operator_profile_id'] as String?,
      error: json['error'] as String?,
    );
  }
}

class MaintenanceTenantRow {
  final String id;
  final String name;
  final String? specialty;
  final String timezone;
  final String status;

  const MaintenanceTenantRow({
    required this.id,
    required this.name,
    this.specialty,
    required this.timezone,
    required this.status,
  });

  factory MaintenanceTenantRow.fromJson(Map<String, dynamic> json) {
    return MaintenanceTenantRow(
      id: json['id'] as String,
      name: json['name'] as String? ?? '—',
      specialty: json['specialty'] as String?,
      timezone: json['timezone'] as String? ?? 'Europe/Istanbul',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class MaintenanceMembershipRow {
  final String id;
  final String tenantId;
  final String tenantName;
  final String profileId;
  final String? profileEmail;
  final String? profileDisplayName;
  final String role;
  final String status;

  const MaintenanceMembershipRow({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.profileId,
    this.profileEmail,
    this.profileDisplayName,
    required this.role,
    required this.status,
  });

  factory MaintenanceMembershipRow.fromJson(Map<String, dynamic> json) {
    return MaintenanceMembershipRow(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      tenantName: json['tenant_name'] as String? ?? '—',
      profileId: json['profile_id'] as String,
      profileEmail: json['profile_email'] as String?,
      profileDisplayName: json['profile_display_name'] as String?,
      role: json['role'] as String,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class MaintenanceProfileGapRow {
  final String id;
  final String? email;
  final String? displayName;

  const MaintenanceProfileGapRow({
    required this.id,
    this.email,
    this.displayName,
  });

  factory MaintenanceProfileGapRow.fromJson(Map<String, dynamic> json) {
    return MaintenanceProfileGapRow(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
    );
  }
}

class MaintenanceAuditEventRow {
  final String id;
  final String action;
  final String? tenantId;
  final String? recordId;
  final DateTime? createdAt;

  const MaintenanceAuditEventRow({
    required this.id,
    required this.action,
    this.tenantId,
    this.recordId,
    this.createdAt,
  });

  factory MaintenanceAuditEventRow.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'];
    DateTime? created;
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw);
    }
    return MaintenanceAuditEventRow(
      id: json['id'] as String,
      action: json['action'] as String? ?? '—',
      tenantId: json['tenant_id'] as String?,
      recordId: json['record_id'] as String?,
      createdAt: created,
    );
  }
}

class MaintenanceBootstrapChain {
  final String? authUserId;
  final bool authUserExists;
  final MaintenanceBootstrapProfile? profile;
  final List<MaintenanceBootstrapMembership> memberships;
  final String? resolvedActiveTenantId;
  final bool chainOk;

  const MaintenanceBootstrapChain({
    this.authUserId,
    required this.authUserExists,
    this.profile,
    required this.memberships,
    this.resolvedActiveTenantId,
    required this.chainOk,
  });

  factory MaintenanceBootstrapChain.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    final membershipsJson = json['memberships'];
    return MaintenanceBootstrapChain(
      authUserId: json['auth_user_id'] as String?,
      authUserExists: json['auth_user_exists'] == true,
      profile: profileJson is Map<String, dynamic>
          ? MaintenanceBootstrapProfile.fromJson(profileJson)
          : null,
      memberships: membershipsJson is List
          ? membershipsJson
              .whereType<Map<String, dynamic>>()
              .map(MaintenanceBootstrapMembership.fromJson)
              .toList()
          : const [],
      resolvedActiveTenantId: json['resolved_active_tenant_id'] as String?,
      chainOk: json['chain_ok'] == true,
    );
  }
}

class MaintenanceBootstrapProfile {
  final String id;
  final String? authUserId;
  final bool hasAuthLink;
  final bool maintenanceOperator;

  const MaintenanceBootstrapProfile({
    required this.id,
    this.authUserId,
    required this.hasAuthLink,
    required this.maintenanceOperator,
  });

  factory MaintenanceBootstrapProfile.fromJson(Map<String, dynamic> json) {
    return MaintenanceBootstrapProfile(
      id: json['id'] as String,
      authUserId: json['auth_user_id'] as String?,
      hasAuthLink: json['has_auth_link'] == true,
      maintenanceOperator: json['maintenance_operator'] == true,
    );
  }
}

class MaintenanceBootstrapMembership {
  final String membershipId;
  final String tenantId;
  final String tenantName;
  final String tenantStatus;
  final String role;
  final String membershipStatus;

  const MaintenanceBootstrapMembership({
    required this.membershipId,
    required this.tenantId,
    required this.tenantName,
    required this.tenantStatus,
    required this.role,
    required this.membershipStatus,
  });

  factory MaintenanceBootstrapMembership.fromJson(Map<String, dynamic> json) {
    return MaintenanceBootstrapMembership(
      membershipId: json['membership_id'] as String,
      tenantId: json['tenant_id'] as String,
      tenantName: json['tenant_name'] as String? ?? '—',
      tenantStatus: json['tenant_status'] as String? ?? 'active',
      role: json['role'] as String,
      membershipStatus: json['membership_status'] as String? ?? 'active',
    );
  }
}
