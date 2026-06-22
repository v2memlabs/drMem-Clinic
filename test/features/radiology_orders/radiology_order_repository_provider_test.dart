import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/radiology_orders/data/mock_async_radiology_order_repository_adapter.dart';
import 'package:v2mem_clinic/features/radiology_orders/data/radiology_order_repository_failure.dart';
import 'package:v2mem_clinic/features/radiology_orders/data/radiology_order_repository_provider.dart';
import 'package:v2mem_clinic/features/radiology_orders/data/supabase_async_radiology_order_repository_stub.dart';
import 'package:v2mem_clinic/features/radiology_orders/data/supabase_radiology_order_repository.dart';

void main() {
  tearDown(() {
    RadiologyOrderRepositoryProvider.clearTestOverrides();
    RadiologyOrderRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('radiology orders capability flag is true', () {
    expect(
      OperationalRecordsRemoteCapabilities.radiologyOrdersTableReady,
      isTrue,
    );
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    RadiologyOrderRepositoryProvider.resetCache();

    expect(
      RadiologyOrderRepositoryProvider.asyncRepository,
      isA<MockAsyncRadiologyOrderRepositoryAdapter>(),
    );
    expect(RadiologyOrderRepositoryProvider.usesRemoteRadiologyOrders, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    RadiologyOrderRepositoryProvider.resetCache();

    expect(
      RadiologyOrderRepositoryProvider.asyncRepository,
      isA<SupabaseAsyncRadiologyOrderRepositoryStub>(),
    );
    expect(RadiologyOrderRepositoryProvider.usesRemoteRadiologyOrders, isFalse);
  });

  test('supabase without session does not resolve Supabase repository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    RadiologyOrderRepositoryProvider.resetCache();

    expect(
      RadiologyOrderRepositoryProvider.asyncRepository,
      isNot(isA<SupabaseRadiologyOrderRepository>()),
    );
  });

  test('unavailable stub throws notConfigured', () async {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    RadiologyOrderRepositoryProvider.resetCache();

    await expectLater(
      RadiologyOrderRepositoryProvider.asyncRepository.getAll(),
      throwsA(
        isA<RadiologyOrderRepositoryException>().having(
          (e) => e.reason,
          'reason',
          RadiologyOrderRepositoryFailure.notConfigured,
        ),
      ),
    );
  });

  test('testOverride bypasses resolved repository', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    RadiologyOrderRepositoryProvider.resetCache();

    const stub = SupabaseAsyncRadiologyOrderRepositoryStub();
    RadiologyOrderRepositoryProvider.testOverride = stub;

    expect(RadiologyOrderRepositoryProvider.asyncRepository, same(stub));
  });
}
