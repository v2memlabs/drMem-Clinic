/// Timeline remote seçim koşulları (test edilebilir).
///
/// Yalnızca [TimelineRepository] — audit/clinical merge yok.
abstract final class TimelineRepositoryBackendGate {
  static bool canUsePatientTimelineRemote({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isTimelineRoleEligible,
  }) {
    if (!_infraReady(
      isMockBackend: isMockBackend,
      isSupabaseConfigured: isSupabaseConfigured,
      isSupabaseInitialized: isSupabaseInitialized,
      isLoggedIn: isLoggedIn,
      isSessionReady: isSessionReady,
      hasActiveTenant: hasActiveTenant,
    )) {
      return false;
    }
    return isTimelineRoleEligible;
  }

  static bool _infraReady({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
  }) {
    if (isMockBackend) return false;
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    return true;
  }
}
