import '../../../core/data/ftr_remote_capabilities.dart';

/// FTR seans notu remote backend seçim koşulları (test edilebilir).
abstract final class PhysiotherapySessionRepositoryBackendGate {
  static bool shouldUseRemoteSessions({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isSessionRoleEligible,
  }) {
    if (isMockBackend) return false;
    if (!FtrRemoteCapabilities.sessionsTableReady) return false;
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isSessionRoleEligible) return false;
    return true;
  }
}
