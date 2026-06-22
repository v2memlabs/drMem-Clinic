enum InventoryCategory {
  sarfMalzeme,
  ilac,
  implant,
  pansuman,
  enjeksiyonIgne,
  atelOrtez,
  ekipman,
  diger,
}

String inventoryCategoryLabel(InventoryCategory category) {
  switch (category) {
    case InventoryCategory.sarfMalzeme:
      return 'Sarf malzeme';
    case InventoryCategory.ilac:
      return 'İlaç';
    case InventoryCategory.implant:
      return 'İmplant';
    case InventoryCategory.pansuman:
      return 'Pansuman';
    case InventoryCategory.enjeksiyonIgne:
      return 'Enjeksiyon / iğne';
    case InventoryCategory.atelOrtez:
      return 'Atel / ortez';
    case InventoryCategory.ekipman:
      return 'Ekipman';
    case InventoryCategory.diger:
      return 'Diğer';
  }
}

class InventoryItem {
  final String id;
  final String name;
  final InventoryCategory category;
  final String unit;
  final double currentQuantity;
  final double minimumQuantity;
  final DateTime? expirationDate;
  final String? location;
  final String? supplierName;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentQuantity,
    required this.minimumQuantity,
    this.expirationDate,
    this.location,
    this.supplierName,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    InventoryCategory? category,
    String? unit,
    double? currentQuantity,
    double? minimumQuantity,
    DateTime? expirationDate,
    bool clearExpirationDate = false,
    String? location,
    String? supplierName,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      expirationDate:
          clearExpirationDate ? null : (expirationDate ?? this.expirationDate),
      location: location ?? this.location,
      supplierName: supplierName ?? this.supplierName,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
