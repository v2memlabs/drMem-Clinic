/// Maintenance Bootstrap Console v2a — tenant + initial admin provisioning modelleri.
library;

class MaintenanceTenantCreateRequest {
  final String name;
  final String? specialty;
  final String timezone;
  final String status;
  final Map<String, dynamic> settingsJson;

  const MaintenanceTenantCreateRequest({
    required this.name,
    this.specialty,
    this.timezone = 'Europe/Istanbul',
    this.status = 'active',
    this.settingsJson = const {},
  });
}

class MaintenanceTenantCreateResult {
  final bool ok;
  final String tenantId;
  final String name;
  final String status;

  const MaintenanceTenantCreateResult({
    required this.ok,
    required this.tenantId,
    required this.name,
    required this.status,
  });

  factory MaintenanceTenantCreateResult.fromJson(Map<String, dynamic> json) {
    return MaintenanceTenantCreateResult(
      ok: json['ok'] == true,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String? ?? '—',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class MaintenanceInitialAdminRequest {
  final String email;
  final String displayName;
  final String loginUsername;
  final String tenantId;

  const MaintenanceInitialAdminRequest({
    required this.email,
    required this.displayName,
    required this.loginUsername,
    required this.tenantId,
  });
}

class MaintenanceUserProvisionResult {
  final bool ok;
  final String operationResult;
  final String? authUserId;
  final String? profileId;
  final String? membershipId;
  final String? loginUsername;

  const MaintenanceUserProvisionResult({
    required this.ok,
    required this.operationResult,
    this.authUserId,
    this.profileId,
    this.membershipId,
    this.loginUsername,
  });

  factory MaintenanceUserProvisionResult.fromJson(Map<String, dynamic> json) {
    return MaintenanceUserProvisionResult(
      ok: json['ok'] == true,
      operationResult: json['operation_result'] as String? ?? 'created',
      authUserId: json['auth_user_id'] as String?,
      profileId: json['profile_id'] as String?,
      membershipId: json['membership_id'] as String?,
      loginUsername: json['login_username'] as String?,
    );
  }

  bool get isAlreadyExists => operationResult == 'already_exists';
}

class MaintenanceBootstrapStatus {
  final bool ok;
  final String? tenantId;
  final String? profileId;
  final String? authUserId;
  final bool authExists;
  final bool profileExists;
  final bool authLinked;
  final bool membershipExists;
  final bool membershipActive;
  final String? role;
  final bool tenantActive;
  final bool chainOk;
  final String? gapCode;

  const MaintenanceBootstrapStatus({
    required this.ok,
    this.tenantId,
    this.profileId,
    this.authUserId,
    required this.authExists,
    required this.profileExists,
    required this.authLinked,
    required this.membershipExists,
    required this.membershipActive,
    this.role,
    required this.tenantActive,
    required this.chainOk,
    this.gapCode,
  });

  factory MaintenanceBootstrapStatus.fromJson(Map<String, dynamic> json) {
    return MaintenanceBootstrapStatus(
      ok: json['ok'] == true,
      tenantId: json['tenant_id'] as String?,
      profileId: json['profile_id'] as String?,
      authUserId: json['auth_user_id'] as String?,
      authExists: json['auth_exists'] == true,
      profileExists: json['profile_exists'] == true,
      authLinked: json['auth_linked'] == true,
      membershipExists: json['membership_exists'] == true,
      membershipActive: json['membership_active'] == true,
      role: json['role'] as String?,
      tenantActive: json['tenant_active'] == true,
      chainOk: json['chain_ok'] == true,
      gapCode: json['gap_code'] as String?,
    );
  }
}
