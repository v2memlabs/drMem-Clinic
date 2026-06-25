/// Klinik kullanıcı oluşturma — admin şifre belirler, davet kaydı yok.
class TenantInviteRequest {
  final String email;
  final String displayName;
  final String loginUsername;
  final String role;
  final String initialPassword;

  const TenantInviteRequest({
    required this.email,
    required this.displayName,
    required this.loginUsername,
    required this.role,
    required this.initialPassword,
  });
}

class TenantInviteResult {
  final String operationResult;
  final String? targetProfileId;
  final String? targetMembershipId;
  final String role;
  final String status;

  const TenantInviteResult({
    required this.operationResult,
    this.targetProfileId,
    this.targetMembershipId,
    required this.role,
    required this.status,
  });

  factory TenantInviteResult.fromJson(Map<String, dynamic> json) {
    return TenantInviteResult(
      operationResult: json['operation_result'] as String? ?? 'created',
      targetProfileId: json['target_profile_id'] as String?,
      targetMembershipId: json['target_membership_id'] as String?,
      role: json['role'] as String? ?? 'assistant_secretary',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class InvitationAcceptResult {
  final String membershipId;
  final String tenantId;
  final String role;
  final String status;

  const InvitationAcceptResult({
    required this.membershipId,
    required this.tenantId,
    required this.role,
    required this.status,
  });

  factory InvitationAcceptResult.fromJson(Map<String, dynamic> json) {
    return InvitationAcceptResult(
      membershipId: json['membership_id'] as String,
      tenantId: json['tenant_id'] as String,
      role: json['role'] as String? ?? 'assistant_secretary',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class InvitationCancelResult {
  final String membershipId;
  final String status;

  const InvitationCancelResult({
    required this.membershipId,
    required this.status,
  });

  factory InvitationCancelResult.fromJson(Map<String, dynamic> json) {
    return InvitationCancelResult(
      membershipId: json['membership_id'] as String,
      status: json['status'] as String? ?? 'disabled',
    );
  }
}
