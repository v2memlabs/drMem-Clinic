import '../../../core/constants/app_roles.dart';
import '../../../core/data/operational_records_remote_capabilities.dart';

/// Ödeme bildirimi remote backend seçim koşulları (test edilebilir).
abstract final class PaymentStaffNotificationRepositoryBackendGate {
  static bool shouldUseRemotePaymentStaffNotifications({
    required bool isMockBackend,
    required bool isSupabaseConfigured,
    required bool isSupabaseInitialized,
    required bool isLoggedIn,
    required bool isSessionReady,
    required bool hasActiveTenant,
    required bool isPaymentRoleEligible,
    required bool isAssistantRole,
  }) {
    if (isMockBackend) return false;
    if (!OperationalRecordsRemoteCapabilities.paymentStaffNotificationsTableReady) {
      return false;
    }
    if (!OperationalRecordsRemoteCapabilities.paymentsTableReady) {
      return false;
    }
    if (!isSupabaseConfigured) return false;
    if (!isSupabaseInitialized) return false;
    if (!isLoggedIn) return false;
    if (!isSessionReady) return false;
    if (!hasActiveTenant) return false;
    if (!isPaymentRoleEligible && !isAssistantRole) return false;
    return true;
  }

  static bool isAssistantRole(String? role) => role == AppRoles.assistant;
}
