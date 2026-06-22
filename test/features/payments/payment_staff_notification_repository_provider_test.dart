import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/payments/data/mock_async_payment_staff_notification_repository_adapter.dart';
import 'package:v2mem_clinic/features/payments/data/payment_staff_notification_repository_failure.dart';
import 'package:v2mem_clinic/features/payments/data/payment_staff_notification_repository_provider.dart';
import 'package:v2mem_clinic/features/payments/data/supabase_payment_staff_notification_repository.dart';
import 'package:v2mem_clinic/features/payments/data/supabase_payment_staff_notification_repository_stub.dart';

void main() {
  tearDown(() {
    PaymentStaffNotificationRepositoryProvider.clearTestOverrides();
    PaymentStaffNotificationRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('payment staff notifications capability flag is true', () {
    expect(
      OperationalRecordsRemoteCapabilities.paymentStaffNotificationsTableReady,
      isTrue,
    );
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PaymentStaffNotificationRepositoryProvider.resetCache();

    expect(
      PaymentStaffNotificationRepositoryProvider.repository,
      isA<MockAsyncPaymentStaffNotificationRepositoryAdapter>(),
    );
    expect(
      PaymentStaffNotificationRepositoryProvider.usesRemotePaymentStaffNotifications,
      isFalse,
    );
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PaymentStaffNotificationRepositoryProvider.resetCache();

    expect(
      PaymentStaffNotificationRepositoryProvider.repository,
      isA<SupabasePaymentStaffNotificationRepositoryStub>(),
    );
    expect(
      PaymentStaffNotificationRepositoryProvider.usesRemotePaymentStaffNotifications,
      isFalse,
    );
  });

  test('supabase without session does not resolve Supabase repository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PaymentStaffNotificationRepositoryProvider.resetCache();

    expect(
      PaymentStaffNotificationRepositoryProvider.repository,
      isNot(isA<SupabasePaymentStaffNotificationRepository>()),
    );
  });

  test('unavailable stub throws notConfigured on listUnread', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PaymentStaffNotificationRepositoryProvider.resetCache();

    await expectLater(
      PaymentStaffNotificationRepositoryProvider.repository.listUnread(),
      throwsA(
        isA<PaymentStaffNotificationRepositoryException>().having(
          (e) => e.reason,
          'reason',
          PaymentStaffNotificationRepositoryFailure.notConfigured,
        ),
      ),
    );
  });

  test('testOverride bypasses resolved repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PaymentStaffNotificationRepositoryProvider.resetCache();

    const stub = SupabasePaymentStaffNotificationRepositoryStub();
    PaymentStaffNotificationRepositoryProvider.testOverride = stub;

    expect(
      PaymentStaffNotificationRepositoryProvider.repository,
      same(stub),
    );
  });
}
