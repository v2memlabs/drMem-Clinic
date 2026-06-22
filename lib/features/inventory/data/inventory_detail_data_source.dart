import '../../../core/data/repository_registry.dart';
import 'inventory_detail_load_result.dart';
import 'inventory_detail_user_messages.dart';
import 'inventory_repository_failure.dart';

abstract final class InventoryDetailDataSource {
  static Future<InventoryDetailLoadResult> loadById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return InventoryDetailLoadResult.notFound();
    }

    try {
      final repo = RepositoryRegistry.inventoryAsync;
      final item = await repo.getById(trimmed);
      if (item == null) {
        return InventoryDetailLoadResult.notFound();
      }
      final movements = await repo.getMovementsByItemId(trimmed);
      return InventoryDetailLoadResult.success(
        item: item,
        movements: movements,
      );
    } on InventoryRepositoryException catch (e) {
      if (e.reason == InventoryRepositoryFailure.notFound) {
        return InventoryDetailLoadResult.notFound();
      }
      return InventoryDetailLoadResult.failure(
        InventoryDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return InventoryDetailLoadResult.failure(
        InventoryDetailUserMessages.genericLoadFailure,
      );
    }
  }
}
