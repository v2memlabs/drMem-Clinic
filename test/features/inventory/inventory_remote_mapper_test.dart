import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/inventory/data/inventory_remote_mapper.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_item.dart';
import 'package:v2mem_clinic/features/inventory/models/inventory_movement.dart';

void main() {
  test('itemFromRow maps remote row', () {
    final item = InventoryRemoteMapper.itemFromRow({
      'id': 'a0000001-0001-4001-8001-000000000001',
      'name': 'Pansuman',
      'category': 'pansuman',
      'unit': 'adet',
      'current_quantity': 12.5,
      'minimum_quantity': 5,
      'expiration_date': '2026-12-01',
      'location': 'Depo A',
      'supplier_name': 'Tedarikçi',
      'notes': 'Not',
      'is_active': true,
      'created_at': '2026-05-01T09:00:00Z',
      'updated_at': '2026-05-02T09:00:00Z',
    });

    expect(item.name, 'Pansuman');
    expect(item.category, InventoryCategory.pansuman);
    expect(item.currentQuantity, 12.5);
    expect(item.expirationDate, isNotNull);
    expect(item.isActive, isTrue);
  });

  test('movementFromRow maps remote row', () {
    final movement = InventoryRemoteMapper.movementFromRow({
      'id': 'm0000001-0001-4001-8001-000000000001',
      'inventory_item_id': 'a0000001-0001-4001-8001-000000000001',
      'movement_type': 'cikis',
      'quantity': 2,
      'movement_date': '2026-05-03T10:00:00Z',
      'performed_by_display': 'Hemşire',
      'note': null,
      'patient_id': null,
      'related_module': null,
      'related_record_id': null,
      'created_at': '2026-05-03T10:00:00Z',
    });

    expect(movement.movementType, InventoryMovementType.cikis);
    expect(movement.performedBy, 'Hemşire');
  });

  test('toInsertItemRow omits mock id', () {
    final row = InventoryRemoteMapper.toInsertItemRow(
      tenantId: 't-1',
      item: InventoryItem(
        id: 'inv-mock',
        name: 'Sarf',
        category: InventoryCategory.sarfMalzeme,
        unit: 'adet',
        currentQuantity: 0,
        minimumQuantity: 1,
        isActive: true,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      ),
    );

    expect(row.containsKey('id'), isFalse);
    expect(row['category'], 'sarfMalzeme');
  });

  test('movementRpcParams strips non-uuid patient id', () {
    final params = InventoryRemoteMapper.movementRpcParams(
      InventoryMovement(
        id: 'mov-1',
        inventoryItemId: 'a0000001-0001-4001-8001-000000000001',
        movementType: InventoryMovementType.giris,
        quantity: 3,
        movementDate: DateTime(2026, 5, 1),
        performedBy: 'Hemşire',
        patientId: 'p-001',
        createdAt: DateTime(2026, 5, 1),
      ),
    );

    expect(params['p_patient_id'], isNull);
  });
}
