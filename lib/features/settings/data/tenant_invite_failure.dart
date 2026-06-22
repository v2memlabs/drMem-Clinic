enum TenantInviteFailure {
  notConfigured,
  forbidden,
  noActiveTenant,
  tenantInactive,
  invalidEmail,
  invalidDisplayName,
  invalidRole,
  invalidLoginUsername,
  loginUsernameTaken,
  authInviteFailed,
  authUserExists,
  selfInviteBlocked,
  profileConflict,
  authUserAlreadyLinked,
  membershipAlreadyActive,
  invitationAlreadyPending,
  invitationNotFound,
  invitationNotPending,
  multiplePendingInvitations,
  invitationAcceptFailed,
  inviteRateLimited,
  authEmailRateLimited,
  databaseBootstrapFailed,
  rollbackFailed,
  invalidResponse,
  unknown,
}

class TenantInviteRepositoryException implements Exception {
  const TenantInviteRepositoryException(this.failure, this.message);

  final TenantInviteFailure failure;
  final String message;

  @override
  String toString() => message;
}
