import '../models/inventory_item.dart';

class InventoryListLoadResult {
  final List<InventoryItem> items;
  final String? errorMessage;

  const InventoryListLoadResult._({required this.items, this.errorMessage});

  factory InventoryListLoadResult.success(List<InventoryItem> items) {
    return InventoryListLoadResult._(items: items);
  }

  factory InventoryListLoadResult.failure(String message) {
    return InventoryListLoadResult._(
      items: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
