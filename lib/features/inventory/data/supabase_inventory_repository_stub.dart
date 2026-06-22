import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';
import 'async_inventory_repository_contract.dart';
import 'inventory_repository.dart';
import 'inventory_repository_failure.dart';

class SupabaseInventoryRepositoryStub
    implements AsyncInventoryRepositoryContract {
  const SupabaseInventoryRepositoryStub();

  static Never _notReady() {
    throw const InventoryRepositoryException(
      InventoryRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<InventoryItem>> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  }) async =>
      _notReady();

  @override
  Future<InventoryItem?> getById(String id) async => _notReady();

  @override
  Future<InventoryItem> add(InventoryItem item) async => _notReady();

  @override
  Future<InventoryItem> update(InventoryItem item) async => _notReady();

  @override
  Future<String?> addMovement(InventoryMovement movement) async => _notReady();

  @override
  Future<List<InventoryMovement>> getMovementsByItemId(
    String inventoryItemId,
  ) async =>
      _notReady();

  @override
  Future<int> countLowStock() async => _notReady();

  @override
  Future<int> countExpiringSoon({
    int days = InventoryRepository.defaultExpiringSoonDays,
  }) async =>
      _notReady();

  @override
  Future<int> countExpired() async => _notReady();
}
