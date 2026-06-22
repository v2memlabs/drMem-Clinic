import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';

abstract interface class AsyncInventoryRepositoryContract {
  Future<List<InventoryItem>> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  });

  Future<InventoryItem?> getById(String id);

  Future<InventoryItem> add(InventoryItem item);

  Future<InventoryItem> update(InventoryItem item);

  Future<String?> addMovement(InventoryMovement movement);

  Future<List<InventoryMovement>> getMovementsByItemId(String inventoryItemId);

  Future<int> countLowStock();

  Future<int> countExpiringSoon({int days});

  Future<int> countExpired();
}
