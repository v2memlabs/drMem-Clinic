/// Clinical encounters remote backend seçim koşulları (test edilebilir, UI bağımsız).
///
/// Full-table `clinical_encounters` yalnızca doctor_admin path — asistan/FTR/hemşire
/// için safe summary ayrı contract/repository (sonraki faz).
abstract final class ClinicalEncounterRepositoryBackendGate {
  static bool shouldUseRemoteClinicalEncounters({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isDoctorFullTableEligible,
  }) {
    if (isMockBackend) return false;
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isDoctorFullTableEligible) return false;
    return true;
  }
}
