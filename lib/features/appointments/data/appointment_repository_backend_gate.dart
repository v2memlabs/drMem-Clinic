/// Appointments remote backend seçim koşulları (test edilebilir, UI bağımsız).
abstract final class AppointmentRepositoryBackendGate {
  static bool shouldUseRemoteAppointments({
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
