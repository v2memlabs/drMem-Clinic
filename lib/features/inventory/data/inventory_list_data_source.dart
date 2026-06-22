import '../../../core/data/repository_registry.dart';
import '../models/inventory_item.dart';
import 'inventory_list_load_result.dart';
import 'inventory_list_user_messages.dart';
import 'inventory_repository_failure.dart';

abstract final class InventoryListDataSource {
  static Future<InventoryListLoadResult> load({
    required String query,
    InventoryCategory? category,
    bool lowStockOnly = false,
    bool expiringSoonOnly = false,
    bool expiredOnly = false,
  }) async {
    try {
      final repo = RepositoryRegistry.inventoryAsync;
      final list = await repo.getFiltered(
        query: query,
        category: category,
        lowStockOnly: lowStockOnly,
        expiringSoonOnly: expiringSoonOnly,
        expiredOnly: expiredOnly,
      );
      return InventoryListLoadResult.success(list);
    } on InventoryRepositoryException catch (e) {
      return InventoryListLoadResult.failure(
        InventoryListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return InventoryListLoadResult.failure(
        InventoryListUserMessages.genericLoadFailure,
      );
    }
  }
}
