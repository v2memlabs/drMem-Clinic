import '../../patient_files/data/patient_file_metadata_parse_helpers.dart';
import '../models/inventory_item.dart';
import '../models/inventory_movement.dart';
import 'inventory_repository_failure.dart';

/// `inventory_items` / `inventory_movements` ↔ domain map.
abstract final class InventoryRemoteMapper {
  static const String itemsTable = 'inventory_items';
  static const String movementsTable = 'inventory_movements';

  static const String itemSelectColumns =
      'id, tenant_id, name, category, unit, current_quantity, minimum_quantity, '
      'expiration_date, location, supplier_name, notes, is_active, created_at, updated_at';

  static const String movementSelectColumns =
      'id, tenant_id, inventory_item_id, movement_type, quantity, movement_date, '
      'performed_by_display, note, patient_id, related_module, related_record_id, created_at';

  static InventoryItem itemFromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);

    return InventoryItem(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      name: PatientFileMetadataParseHelpers.requireString(map, 'name'),
      category: _enumFromDb(
        InventoryCategory.values,
        map['category'],
        InventoryRepositoryFailure.invalidRow,
      ),
      unit: PatientFileMetadataParseHelpers.requireString(map, 'unit'),
      currentQuantity: _parseQuantity(map['current_quantity']),
      minimumQuantity: _parseQuantity(map['minimum_quantity']),
      expirationDate: _parseDateOnly(map['expiration_date']),
      location: PatientFileMetadataParseHelpers.optionalString(map['location']),
      supplierName:
          PatientFileMetadataParseHelpers.optionalString(map['supplier_name']),
      notes: PatientFileMetadataParseHelpers.optionalString(map['notes']),
      isActive: map['is_active'] == true,
      createdAt: PatientFileMetadataParseHelpers.requireDateTime(map['created_at']),
      updatedAt: PatientFileMetadataParseHelpers.requireDateTime(map['updated_at']),
    );
  }

  static InventoryMovement movementFromRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);

    return InventoryMovement(
      id: PatientFileMetadataParseHelpers.requireString(map, 'id'),
      inventoryItemId:
          PatientFileMetadataParseHelpers.requireString(map, 'inventory_item_id'),
      movementType: _enumFromDb(
        InventoryMovementType.values,
        map['movement_type'],
        InventoryRepositoryFailure.invalidRow,
      ),
      quantity: _parseQuantity(map['quantity']),
      movementDate:
          PatientFileMetadataParseHelpers.requireDateTime(map['movement_date']),
      performedBy: PatientFileMetadataParseHelpers.optionalString(
            map['performed_by_display'],
          ) ??
          '—',
      note: PatientFileMetadataParseHelpers.optionalString(map['note']),
      patientId: PatientFileMetadataParseHelpers.optionalString(map['patient_id']),
      relatedModule:
          PatientFileMetadataParseHelpers.optionalString(map['related_module']),
      relatedRecordId:
          PatientFileMetadataParseHelpers.optionalString(map['related_record_id']),
      createdAt: PatientFileMetadataParseHelpers.requireDateTime(map['created_at']),
    );
  }

  static Map<String, dynamic> toInsertItemRow({
    required String tenantId,
    required InventoryItem item,
    String? createdByProfileId,
  }) {
    return {
      'tenant_id': tenantId,
      'name': item.name.trim(),
      'category': item.category.name,
      'unit': item.unit.trim(),
      'current_quantity': item.currentQuantity,
      'minimum_quantity': item.minimumQuantity,
      'expiration_date': item.expirationDate != null
          ? _dateOnlyString(item.expirationDate!)
          : null,
      'location': item.location?.trim().isEmpty ?? true ? null : item.location!.trim(),
      'supplier_name':
          item.supplierName?.trim().isEmpty ?? true ? null : item.supplierName!.trim(),
      'notes': item.notes?.trim().isEmpty ?? true ? null : item.notes!.trim(),
      'is_active': item.isActive,
      if (createdByProfileId != null) 'created_by': createdByProfileId,
    };
  }

  static Map<String, dynamic> toUpdateItemRow(InventoryItem item) {
    return {
      'name': item.name.trim(),
      'category': item.category.name,
      'unit': item.unit.trim(),
      'current_quantity': item.currentQuantity,
      'minimum_quantity': item.minimumQuantity,
      'expiration_date': item.expirationDate != null
          ? _dateOnlyString(item.expirationDate!)
          : null,
      'location': item.location?.trim().isEmpty ?? true ? null : item.location!.trim(),
      'supplier_name':
          item.supplierName?.trim().isEmpty ?? true ? null : item.supplierName!.trim(),
      'notes': item.notes?.trim().isEmpty ?? true ? null : item.notes!.trim(),
      'is_active': item.isActive,
    };
  }

  static Map<String, dynamic> movementRpcParams(InventoryMovement movement) {
    return {
      'p_inventory_item_id': movement.inventoryItemId.trim(),
      'p_movement_type': movement.movementType.name,
      'p_quantity': movement.quantity,
      'p_movement_date': movement.movementDate.toUtc().toIso8601String(),
      'p_performed_by_display': movement.performedBy.trim().isEmpty
          ? null
          : movement.performedBy.trim(),
      'p_note': movement.note?.trim().isEmpty ?? true ? null : movement.note!.trim(),
      'p_patient_id': _optionalUuid(movement.patientId),
      'p_related_module': movement.relatedModule?.trim().isEmpty ?? true
          ? null
          : movement.relatedModule!.trim(),
      'p_related_record_id': _optionalUuid(movement.relatedRecordId),
    };
  }

  static String? _optionalUuid(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (!uuidPattern.hasMatch(value)) return null;
    return value;
  }

  static DateTime? _parseDateOnly(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    return parsed;
  }

  static String _dateOnlyString(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static double _parseQuantity(Object? value) {
    if (value == null) {
      throw const InventoryRepositoryException(
        InventoryRepositoryFailure.invalidRow,
      );
    }
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      throw const InventoryRepositoryException(
        InventoryRepositoryFailure.invalidRow,
      );
    }
    return parsed;
  }

  static T _enumFromDb<T extends Enum>(
    List<T> values,
    Object? raw,
    InventoryRepositoryFailure failure,
  ) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw InventoryRepositoryException(failure);
    }
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw InventoryRepositoryException(failure);
  }
}
