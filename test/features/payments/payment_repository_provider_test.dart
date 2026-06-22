import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/payments/data/mock_async_payment_repository_adapter.dart';
import 'package:v2mem_clinic/features/payments/data/payment_repository_provider.dart';
import 'package:v2mem_clinic/features/payments/data/supabase_payment_repository.dart';
import 'package:v2mem_clinic/features/payments/data/supabase_payment_repository_stub.dart';

void main() {
  tearDown(() {
    PaymentRepositoryProvider.clearTestOverrides();
    PaymentRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('payments capability flag is true', () {
    expect(OperationalRecordsRemoteCapabilities.paymentsTableReady, isTrue);
  });

  test('inventory capability flag is true in v2b', () {
    expect(OperationalRecordsRemoteCapabilities.inventoryTablesReady, isTrue);
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PaymentRepositoryProvider.resetCache();

    expect(
      PaymentRepositoryProvider.asyncRepository,
      isA<MockAsyncPaymentRepositoryAdapter>(),
    );
    expect(PaymentRepositoryProvider.usesRemotePayments, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PaymentRepositoryProvider.resetCache();

    expect(
      PaymentRepositoryProvider.asyncRepository,
      isA<SupabasePaymentRepositoryStub>(),
    );
    expect(PaymentRepositoryProvider.usesRemotePayments, isFalse);
  });

  test('supabase without session does not resolve SupabasePaymentRepository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    PaymentRepositoryProvider.resetCache();

    expect(
      PaymentRepositoryProvider.asyncRepository,
      isNot(isA<SupabasePaymentRepository>()),
    );
  });

  test('testOverride bypasses resolved repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    PaymentRepositoryProvider.resetCache();

    const stub = SupabasePaymentRepositoryStub();
    PaymentRepositoryProvider.testOverride = stub;

    expect(PaymentRepositoryProvider.asyncRepository, same(stub));
  });
}
