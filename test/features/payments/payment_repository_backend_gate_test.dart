import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/payments/data/payment_repository_backend_gate.dart';

void main() {
  test('payments capability flag is enabled in v2a', () {
    expect(OperationalRecordsRemoteCapabilities.paymentsTableReady, isTrue);
  });

  test('remote requires full gate chain', () {
    expect(
      PaymentRepositoryBackendGate.shouldUseRemotePayments(
        isMockBackend: true,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isPaymentRoleEligible: true,
      ),
      isFalse,
    );

    expect(
      PaymentRepositoryBackendGate.shouldUseRemotePayments(
        isMockBackend: false,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isPaymentRoleEligible: true,
      ),
      isTrue,
    );

    expect(
      PaymentRepositoryBackendGate.shouldUseRemotePayments(
        isMockBackend: false,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isPaymentRoleEligible: false,
      ),
      isFalse,
    );
  });
}
