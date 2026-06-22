enum InventoryMovementType {
  giris,
  cikis,
  duzeltme,
}

String inventoryMovementTypeLabel(InventoryMovementType type) {
  switch (type) {
    case InventoryMovementType.giris:
      return 'Giriş';
    case InventoryMovementType.cikis:
      return 'Çıkış';
    case InventoryMovementType.duzeltme:
      return 'Düzeltme';
  }
}

class InventoryMovement {
  final String id;
  final String inventoryItemId;
  final InventoryMovementType movementType;
  final double quantity;
  final DateTime movementDate;
  final String performedBy;
  final String? note;
  final String? patientId;
  final String? relatedModule;
  final String? relatedRecordId;
  final DateTime createdAt;

  const InventoryMovement({
    required this.id,
    required this.inventoryItemId,
    required this.movementType,
    required this.quantity,
    required this.movementDate,
    required this.performedBy,
    this.note,
    this.patientId,
    this.relatedModule,
    this.relatedRecordId,
    required this.createdAt,
  });
}
