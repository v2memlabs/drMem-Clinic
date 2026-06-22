enum RadiologyModality { xRay, mri, bt, usg }

enum RadiologySide { sag, sol, bilateral, belirtilmedi }

enum RadiologyOrderStatus { taslak, istendi, tamamlandi, iptal }

enum RadiologyPriority { rutin, acil }

class RadiologyOrderLine {
  final RadiologyModality modality;
  final String bodyRegion;
  final RadiologySide side;
  final String clinicalIndication;
  final bool withContrast;
  final String? notes;

  const RadiologyOrderLine({
    required this.modality,
    required this.bodyRegion,
    this.side = RadiologySide.belirtilmedi,
    required this.clinicalIndication,
    this.withContrast = false,
    this.notes,
  });
}

class RadiologyOrder {
  final String id;
  final String patientId;
  final String patientName;
  final String? clinicalEncounterId;
  /// Muayene protokol no — kayıt anında snapshot (ör. M-2026-00001).
  final String? clinicalEncounterProtocolNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final RadiologyOrderStatus status;
  final RadiologyPriority priority;
  final String diagnosis;
  final List<RadiologyOrderLine> lines;
  final String? additionalNotes;

  const RadiologyOrder({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.clinicalEncounterId,
    this.clinicalEncounterProtocolNumber,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    required this.status,
    this.priority = RadiologyPriority.rutin,
    required this.diagnosis,
    required this.lines,
    this.additionalNotes,
  });

  RadiologyOrder copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? clinicalEncounterId,
    String? clinicalEncounterProtocolNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    RadiologyOrderStatus? status,
    RadiologyPriority? priority,
    String? diagnosis,
    List<RadiologyOrderLine>? lines,
    String? additionalNotes,
  }) {
    return RadiologyOrder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      clinicalEncounterId: clinicalEncounterId ?? this.clinicalEncounterId,
      clinicalEncounterProtocolNumber: clinicalEncounterProtocolNumber ??
          this.clinicalEncounterProtocolNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      diagnosis: diagnosis ?? this.diagnosis,
      lines: lines ?? this.lines,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }

  String? get displayProtocolNumber {
    final value = clinicalEncounterProtocolNumber?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

String radiologyModalityLabel(RadiologyModality modality) {
  switch (modality) {
    case RadiologyModality.xRay:
      return 'X-Ray';
    case RadiologyModality.mri:
      return 'MRI';
    case RadiologyModality.bt:
      return 'BT';
    case RadiologyModality.usg:
      return 'USG';
  }
}

String radiologySideLabel(RadiologySide side) {
  switch (side) {
    case RadiologySide.sag:
      return 'Sağ';
    case RadiologySide.sol:
      return 'Sol';
    case RadiologySide.bilateral:
      return 'Bilateral';
    case RadiologySide.belirtilmedi:
      return 'Belirtilmedi';
  }
}

String radiologyOrderStatusLabel(RadiologyOrderStatus status) {
  switch (status) {
    case RadiologyOrderStatus.taslak:
      return 'Taslak';
    case RadiologyOrderStatus.istendi:
      return 'İstendi';
    case RadiologyOrderStatus.tamamlandi:
      return 'Tamamlandı';
    case RadiologyOrderStatus.iptal:
      return 'İptal';
  }
}

String radiologyPriorityLabel(RadiologyPriority priority) {
  switch (priority) {
    case RadiologyPriority.rutin:
      return 'Rutin';
    case RadiologyPriority.acil:
      return 'Acil';
  }
}
