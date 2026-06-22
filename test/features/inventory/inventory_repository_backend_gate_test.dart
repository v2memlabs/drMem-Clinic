import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/operational_records_remote_capabilities.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_repository_backend_gate.dart';

void main() {
  test('inventory capability flag enabled in v2b', () {
    expect(OperationalRecordsRemoteCapabilities.inventoryTablesReady, isTrue);
    expect(OperationalRecordsRemoteCapabilities.paymentsTableReady, isTrue);
    expect(OperationalRecordsRemoteCapabilities.consentsTableReady, isTrue);
  });

  test('remote requires doctor/nurse eligible role', () {
    expect(
      InventoryRepositoryBackendGate.shouldUseRemoteInventory(
        isMockBackend: false,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isInventoryRoleEligible: true,
      ),
      isTrue,
    );

    expect(
      InventoryRepositoryBackendGate.shouldUseRemoteInventory(
        isMockBackend: false,
        isSupabaseConfigured: true,
        isSupabaseInitialized: true,
        isLoggedIn: true,
        isSessionReady: true,
        hasActiveTenant: true,
        isInventoryRoleEligible: false,
      ),
      isFalse,
    );
  });
}
