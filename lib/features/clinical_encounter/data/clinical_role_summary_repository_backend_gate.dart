/// Role-based safe clinical summary remote seçim koşulları (test edilebilir).
///
/// Full-table [ClinicalEncounterRepository] ile karıştırılmaz.
abstract final class ClinicalRoleSummaryRepositoryBackendGate {
  static bool canUseAssistantClinicalSummaryRemote({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isAssistantSummaryRoleEligible,
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
    return isAssistantSummaryRoleEligible;
  }

  static bool canUsePhysiotherapistClinicalSummaryRemote({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isPhysiotherapistSummaryRoleEligible,
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
    return isPhysiotherapistSummaryRoleEligible;
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
