import '../../../core/data/operational_records_remote_capabilities.dart';

abstract final class RadiologyOrderRepositoryBackendGate {
  static bool shouldUseRemoteRadiologyOrders({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isRadiologyOrderRoleEligible,
  }) {
    if (isMockBackend) return false;
    if (!OperationalRecordsRemoteCapabilities.radiologyOrdersTableReady) {
      return false;
    }
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isRadiologyOrderRoleEligible) return false;
    return true;
  }
}
