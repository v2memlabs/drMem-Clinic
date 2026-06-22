import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/payments/data/payment_staff_notification_repository_backend_gate.dart';

void main() {
  group('PaymentStaffNotificationRepositoryBackendGate', () {
    test('allows assistant role without payment permissions', () {
      expect(
        PaymentStaffNotificationRepositoryBackendGate
            .shouldUseRemotePaymentStaffNotifications(
          isMockBackend: false,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isPaymentRoleEligible: false,
          isAssistantRole: true,
        ),
        isTrue,
      );
    });

    test('blocks mock backend', () {
      expect(
        PaymentStaffNotificationRepositoryBackendGate
            .shouldUseRemotePaymentStaffNotifications(
          isMockBackend: true,
          isSupabaseConfigured: true,
          isSupabaseInitialized: true,
          isLoggedIn: true,
          isSessionReady: true,
          hasActiveTenant: true,
          isPaymentRoleEligible: true,
          isAssistantRole: false,
        ),
        isFalse,
      );
    });

    test('isAssistantRole helper', () {
      expect(
        PaymentStaffNotificationRepositoryBackendGate.isAssistantRole(
          AppRoles.assistant,
        ),
        isTrue,
      );
      expect(
        PaymentStaffNotificationRepositoryBackendGate.isAssistantRole(
          AppRoles.doctor,
        ),
        isFalse,
      );
    });
  });
}
