import '../../../core/data/operational_records_remote_capabilities.dart';

abstract final class LabOrderTemplateRepositoryBackendGate {
  static bool shouldUseRemoteLabOrderTemplates({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isLabOrderTemplateRoleEligible,
  }) {
    if (isMockBackend) return false;
    if (!OperationalRecordsRemoteCapabilities.labOrderTemplatesTableReady) {
      return false;
    }
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isLabOrderTemplateRoleEligible) return false;
    return true;
  }
}
