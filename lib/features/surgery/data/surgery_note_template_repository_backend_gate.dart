import '../../../core/data/operational_records_remote_capabilities.dart';

abstract final class SurgeryNoteTemplateRepositoryBackendGate {
  static bool shouldUseRemoteSurgeryNoteTemplates({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isSurgeryRoleEligible,
  }) {
    if (isMockBackend) return false;
    if (!OperationalRecordsRemoteCapabilities.surgeryNoteTemplatesTableReady) {
      return false;
    }
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isSurgeryRoleEligible) return false;
    return true;
  }
}
