/// Audit log remote backend seçim koşulları (test edilebilir).
abstract final class AuditLogRepositoryBackendGate {
  static bool shouldUseRemoteAuditLogs({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isAuditRoleEligible,
  }) {
    if (isMockBackend) return false;
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isAuditRoleEligible) return false;
    return true;
  }
}
