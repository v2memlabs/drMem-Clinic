/// [AuthSessionBridge] oturum uygulama sonucu.
enum SessionBridgeFailure {
  unknownRole,
  roleMismatch,
  inactiveMembership,
  inactiveTenant,
  membershipNotFound,
  tenantLoadFailed,
  bootstrapNotReady,
}

class SessionBridgeResult {
  final bool success;
  final SessionBridgeFailure? failure;

  const SessionBridgeResult._({
    required this.success,
    this.failure,
  });

  factory SessionBridgeResult.applied() {
    return const SessionBridgeResult._(success: true);
  }

  factory SessionBridgeResult.failure(SessionBridgeFailure reason) {
    return SessionBridgeResult._(
      success: false,
      failure: reason,
    );
  }
}
