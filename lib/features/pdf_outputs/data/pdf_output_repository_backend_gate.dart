/// PDF çıktı remote backend seçim koşulları (test edilebilir, UI bağımsız).
///
/// Yalnızca doctor_admin PDF list/detail — mevcut [AuthSession.canViewPdfOutputs].
abstract final class PdfOutputRepositoryBackendGate {
  static bool shouldUseRemotePdfOutputs({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isPdfOutputRoleEligible,
  }) {
    if (isMockBackend) return false;
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isPdfOutputRoleEligible) return false;
    return true;
  }
}
