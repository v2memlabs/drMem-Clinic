import '../../../core/data/repository_registry.dart';
import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';
import 'inventory_list_user_messages.dart';
import 'inventory_repository_failure.dart';

class InventoryFormSaveResult {
  final InventoryItem? item;
  final String? errorMessage;

  const InventoryFormSaveResult._({this.item, this.errorMessage});

  factory InventoryFormSaveResult.success(InventoryItem item) {
    return InventoryFormSaveResult._(item: item);
  }

  factory InventoryFormSaveResult.failure(String message) {
    return InventoryFormSaveResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

class InventoryMovementSaveResult {
  final String? validationError;
  final String? repositoryError;

  const InventoryMovementSaveResult._({
    this.validationError,
    this.repositoryError,
  });

  factory InventoryMovementSaveResult.success() {
    return const InventoryMovementSaveResult._();
  }

  factory InventoryMovementSaveResult.validation(String message) {
    return InventoryMovementSaveResult._(validationError: message);
  }

  factory InventoryMovementSaveResult.failure(String message) {
    return InventoryMovementSaveResult._(repositoryError: message);
  }

  bool get hasError =>
      (validationError != null && validationError!.isNotEmpty) ||
      (repositoryError != null && repositoryError!.isNotEmpty);
}

class InventoryFormLoadResult {
  final InventoryItem? item;
  final String? errorMessage;
  final bool notFound;

  const InventoryFormLoadResult._({
    this.item,
    this.errorMessage,
    this.notFound = false,
  });

  factory InventoryFormLoadResult.success(InventoryItem item) {
    return InventoryFormLoadResult._(item: item);
  }

  factory InventoryFormLoadResult.failure(String message) {
    return InventoryFormLoadResult._(errorMessage: message);
  }

  factory InventoryFormLoadResult.notFound() {
    return const InventoryFormLoadResult._(notFound: true);
  }

  bool get hasError =>
      notFound || (errorMessage != null && errorMessage!.isNotEmpty);
}

abstract final class InventoryFormDataSource {
  static Future<InventoryFormLoadResult> loadById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return InventoryFormLoadResult.notFound();
    }

    try {
      final item = await RepositoryRegistry.inventoryAsync.getById(trimmed);
      if (item == null) {
        return InventoryFormLoadResult.notFound();
      }
      return InventoryFormLoadResult.success(item);
    } on InventoryRepositoryException catch (e) {
      if (e.reason == InventoryRepositoryFailure.notFound) {
        return InventoryFormLoadResult.notFound();
      }
      return InventoryFormLoadResult.failure(
        InventoryListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return InventoryFormLoadResult.failure(
        InventoryListUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<InventoryFormSaveResult> add(InventoryItem item) async {
    try {
      final saved = await RepositoryRegistry.inventoryAsync.add(item);
      return InventoryFormSaveResult.success(saved);
    } on InventoryRepositoryException catch (e) {
      return InventoryFormSaveResult.failure(
        InventoryListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return InventoryFormSaveResult.failure(
        InventoryListUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<InventoryFormSaveResult> update(InventoryItem item) async {
    try {
      final saved = await RepositoryRegistry.inventoryAsync.update(item);
      return InventoryFormSaveResult.success(saved);
    } on InventoryRepositoryException catch (e) {
      return InventoryFormSaveResult.failure(
        InventoryListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return InventoryFormSaveResult.failure(
        InventoryListUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<InventoryMovementSaveResult> addMovement(
    InventoryMovement movement,
  ) async {
    try {
      final validation =
          await RepositoryRegistry.inventoryAsync.addMovement(movement);
      if (validation != null && validation.isNotEmpty) {
        return InventoryMovementSaveResult.validation(validation);
      }
      return InventoryMovementSaveResult.success();
    } on InventoryRepositoryException catch (e) {
      return InventoryMovementSaveResult.failure(
        InventoryListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return InventoryMovementSaveResult.failure(
        InventoryListUserMessages.genericLoadFailure,
      );
    }
  }
}
