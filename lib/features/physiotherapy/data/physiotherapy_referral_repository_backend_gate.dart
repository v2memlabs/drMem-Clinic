import '../../../core/data/ftr_remote_capabilities.dart';

/// FTR yönlendirme remote backend seçim koşulları (test edilebilir).
abstract final class PhysiotherapyReferralRepositoryBackendGate {
  static bool shouldUseRemoteReferrals({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isReferralRoleEligible,
  }) {
    if (isMockBackend) return false;
    if (!FtrRemoteCapabilities.referralsTableReady) return false;
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isReferralRoleEligible) return false;
    return true;
  }
}
