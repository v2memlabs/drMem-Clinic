/// Patient file metadata remote seçim koşulları (test edilebilir).
///
/// Yalnızca [PatientFileMetadataRepository] seçimi — Storage upload/download,
/// signed URL veya dosya içeriği bu gate'te yok.
abstract final class PatientFileMetadataRepositoryBackendGate {
  static bool canUsePatientFileMetadataRemote({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isPatientFileMetadataRoleEligible,
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
    return isPatientFileMetadataRoleEligible;
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
