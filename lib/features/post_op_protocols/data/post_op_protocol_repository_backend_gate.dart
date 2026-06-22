import '../../../core/data/operational_records_remote_capabilities.dart';

abstract final class PostOpProtocolRepositoryBackendGate {
  static bool shouldUseRemotePostOpProtocols({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isPostOpProtocolRoleEligible,
  }) {
    if (isMockBackend) return false;
    if (!OperationalRecordsRemoteCapabilities.postOpProtocolsTableReady) {
      return false;
    }
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isPostOpProtocolRoleEligible) return false;
    return true;
  }
}
