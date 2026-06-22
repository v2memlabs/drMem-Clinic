import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';
import 'mock_inventory.dart';

class InventoryRepository {
  InventoryRepository._();

  static final InventoryRepository instance = InventoryRepository._();

  static const int defaultExpiringSoonDays = 30;

  List<InventoryItem> getAll() => List.unmodifiable(mockInventoryItems);

  List<InventoryItem> getActive() =>
      mockInventoryItems.where((e) => e.isActive).toList();

  InventoryItem? getById(String id) {
    for (final item in mockInventoryItems) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<InventoryItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getActive();

    return getActive().where((item) => _matchesQuery(item, q)).toList();
  }

  List<InventoryItem> getFiltered({
    String? query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
    bool includeInactive = false,
  }) {
    Iterable<InventoryItem> list =
        includeInactive ? mockInventoryItems : getActive();

    if (category != null) {
      list = list.where((e) => e.category == category);
    }
    if (lowStockOnly) {
      list = list.where(isLowStock);
    }
    if (expiringSoonOnly) {
      list = list.where((e) => isExpiringSoon(e));
    }
    if (expiredOnly) {
      list = list.where(isExpired);
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((e) => _matchesQuery(e, q));
    }

    final result = List<InventoryItem>.from(list);
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  void add(InventoryItem item) => addMockInventoryItem(item);

  void update(InventoryItem item) {
    final index = indexOfMockInventoryItem(item.id);
    if (index >= 0) {
      updateMockInventoryItem(index, item);
    }
  }

  /// Hareket ekler ve stok miktarını günceller. Hata mesajı döner; başarıda null.
  String? addMovement(InventoryMovement movement) {
    final index = indexOfMockInventoryItem(movement.inventoryItemId);
    if (index < 0) return 'Stok kartı bulunamadı.';

    final item = mockInventoryItems[index];
    if (!item.isActive) return 'Pasif stok kartına hareket eklenemez.';

    if (movement.quantity <= 0) return 'Miktar sıfırdan büyük olmalıdır.';

    double newQty;
    switch (movement.movementType) {
      case InventoryMovementType.giris:
        newQty = item.currentQuantity + movement.quantity;
      case InventoryMovementType.cikis:
        if (movement.quantity > item.currentQuantity) {
          return 'Çıkış miktarı mevcut stoktan fazla olamaz.';
        }
        newQty = item.currentQuantity - movement.quantity;
      case InventoryMovementType.duzeltme:
        newQty = movement.quantity;
        if (newQty < 0) return 'Stok miktarı negatif olamaz.';
    }

    addMockInventoryMovement(movement);
    updateMockInventoryItem(
      index,
      item.copyWith(
        currentQuantity: newQty,
        updatedAt: DateTime.now(),
      ),
    );
    return null;
  }

  List<InventoryMovement> getMovementsByItemId(String inventoryItemId) {
    final list = mockInventoryMovements
        .where((m) => m.inventoryItemId == inventoryItemId)
        .toList();
    list.sort((a, b) => b.movementDate.compareTo(a.movementDate));
    return list;
  }

  List<InventoryMovement> getRecentMovements({int limit = 5}) {
    final list = List<InventoryMovement>.from(mockInventoryMovements);
    list.sort((a, b) => b.movementDate.compareTo(a.movementDate));
    if (list.length <= limit) return list;
    return list.take(limit).toList();
  }

  int countLowStock() => getActive().where(isLowStock).length;

  int countExpiringSoon({int days = defaultExpiringSoonDays}) =>
      getActive().where((e) => isExpiringSoon(e, days: days)).length;

  int countExpired() => getActive().where(isExpired).length;

  static bool isLowStock(InventoryItem item) =>
      item.currentQuantity <= item.minimumQuantity;

  static bool isExpired(InventoryItem item) {
    final exp = item.expirationDate;
    if (exp == null) return false;
    final today = DateTime.now();
    final endOfExpDay = DateTime(exp.year, exp.month, exp.day, 23, 59, 59);
    return endOfExpDay.isBefore(DateTime(today.year, today.month, today.day));
  }

  static bool isExpiringSoon(InventoryItem item, {int days = defaultExpiringSoonDays}) {
    final exp = item.expirationDate;
    if (exp == null) return false;
    if (isExpired(item)) return false;
    final limit = DateTime.now().add(Duration(days: days));
    return !exp.isAfter(limit);
  }

  static String? stockAlertLabel(InventoryItem item) {
    if (isExpired(item)) return 'SKT geçmiş';
    if (isLowStock(item)) return 'Düşük stok';
    if (isExpiringSoon(item)) return 'SKT yakın';
    return null;
  }

  bool _matchesQuery(InventoryItem item, String q) {
    if (item.name.toLowerCase().contains(q)) return true;
    if (inventoryCategoryLabel(item.category).toLowerCase().contains(q)) {
      return true;
    }
    if ((item.location ?? '').toLowerCase().contains(q)) return true;
    if ((item.supplierName ?? '').toLowerCase().contains(q)) return true;
    if ((item.notes ?? '').toLowerCase().contains(q)) return true;
    if (item.unit.toLowerCase().contains(q)) return true;
    return false;
  }
}
