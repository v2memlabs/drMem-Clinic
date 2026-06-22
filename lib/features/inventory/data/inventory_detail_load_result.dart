import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';

class InventoryDetailLoadResult {
  final InventoryItem? item;
  final List<InventoryMovement> movements;
  final String? errorMessage;
  final bool notFound;

  const InventoryDetailLoadResult._({
    this.item,
    this.movements = const [],
    this.errorMessage,
    this.notFound = false,
  });

  factory InventoryDetailLoadResult.success({
    required InventoryItem item,
    required List<InventoryMovement> movements,
  }) {
    return InventoryDetailLoadResult._(item: item, movements: movements);
  }

  factory InventoryDetailLoadResult.notFound() {
    return const InventoryDetailLoadResult._(notFound: true);
  }

  factory InventoryDetailLoadResult.failure(String message) {
    return InventoryDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
