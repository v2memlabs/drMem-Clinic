import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository_provider.dart';
import 'package:v2mem_clinic/features/inventory/data/mock_async_inventory_repository_adapter.dart';
import 'package:v2mem_clinic/features/inventory/data/supabase_inventory_repository.dart';
import 'package:v2mem_clinic/features/inventory/data/supabase_inventory_repository_stub.dart';

void main() {
  tearDown(() {
    InventoryRepositoryProvider.clearTestOverrides();
    InventoryRepositoryProvider.resetCache();
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('inventoryTablesReady is true in v2b', () {
    expect(OperationalRecordsRemoteCapabilities.inventoryTablesReady, isTrue);
  });

  test('mock backend uses mock async adapter', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    InventoryRepositoryProvider.resetCache();

    expect(
      InventoryRepositoryProvider.asyncRepository,
      isA<MockAsyncInventoryRepositoryAdapter>(),
    );
    expect(InventoryRepositoryProvider.usesRemoteInventory, isFalse);
  });

  test('supabase without session uses unavailable stub', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    InventoryRepositoryProvider.resetCache();

    expect(
      InventoryRepositoryProvider.asyncRepository,
      isA<SupabaseInventoryRepositoryStub>(),
    );
    expect(InventoryRepositoryProvider.usesRemoteInventory, isFalse);
  });

  test('supabase without session does not resolve SupabaseInventoryRepository', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    InventoryRepositoryProvider.resetCache();

    expect(
      InventoryRepositoryProvider.asyncRepository,
      isNot(isA<SupabaseInventoryRepository>()),
    );
  });

  test('mock adapter exposes safe stock counts', () async {
    AppBackendConfig.activeBackend = DataBackend.mock;
    InventoryRepositoryProvider.resetCache();
    final repo = InventoryRepositoryProvider.asyncRepository;
    final low = await repo.countLowStock();
    expect(low, greaterThanOrEqualTo(0));
  });
}
