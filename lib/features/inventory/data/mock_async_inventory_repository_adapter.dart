import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';
import 'async_inventory_repository_contract.dart';
import 'inventory_repository.dart';

class MockAsyncInventoryRepositoryAdapter
    implements AsyncInventoryRepositoryContract {
  InventoryRepository get _sync => InventoryRepository.instance;

  @override
  Future<List<InventoryItem>> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  }) async {
    return _sync.getFiltered(
      query: query,
      category: category,
      lowStockOnly: lowStockOnly,
      expiringSoonOnly: expiringSoonOnly,
      expiredOnly: expiredOnly,
      includeInactive: includeInactive,
    );
  }

  @override
  Future<InventoryItem?> getById(String id) async => _sync.getById(id);

  @override
  Future<InventoryItem> add(InventoryItem item) async {
    _sync.add(item);
    return item;
  }

  @override
  Future<InventoryItem> update(InventoryItem item) async {
    _sync.update(item);
    return item;
  }

  @override
  Future<String?> addMovement(InventoryMovement movement) async =>
      _sync.addMovement(movement);

  @override
  Future<List<InventoryMovement>> getMovementsByItemId(
    String inventoryItemId,
  ) async =>
      _sync.getMovementsByItemId(inventoryItemId);

  @override
  Future<int> countLowStock() async => _sync.countLowStock();

  @override
  Future<int> countExpiringSoon({int days = InventoryRepository.defaultExpiringSoonDays}) async =>
      _sync.countExpiringSoon(days: days);

  @override
  Future<int> countExpired() async => _sync.countExpired();
}
