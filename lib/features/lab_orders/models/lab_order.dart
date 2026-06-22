import 'lab_test_catalog.dart';

enum LabOrderStatus { taslak, istendi, tamamlandi, iptal }

enum LabOrderReason {
  preoperatifHazirlik,
  enfeksiyonSuphesi,
  postoperatif,
  takip,
}

class LabOrder {
  final String id;
  final String patientId;
  final String patientName;
  final String? clinicalEncounterId;
  /// Muayene protokol no — kayıt anında snapshot (ör. M-2026-00001).
  final String? clinicalEncounterProtocolNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final LabOrderStatus status;
  final String diagnosis;
  final LabOrderReason orderReason;
  final List<LabTestCode> selectedTests;
  final List<String> selectedCustomTestIds;
  final InfectionContext infectionContext;
  final String? infectionNotes;
  final String? preoperativeNotes;
  final String? ekgNotes;
  final String? additionalNotes;
  final String? templateId;
  final String? templateName;

  const LabOrder({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.clinicalEncounterId,
    this.clinicalEncounterProtocolNumber,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    required this.status,
    required this.diagnosis,
    this.orderReason = LabOrderReason.preoperatifHazirlik,
    required this.selectedTests,
    this.selectedCustomTestIds = const [],
    this.infectionContext = InfectionContext.yok,
    this.infectionNotes,
    this.preoperativeNotes,
    this.ekgNotes,
    this.additionalNotes,
    this.templateId,
    this.templateName,
  });

  LabOrder copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? clinicalEncounterId,
    String? clinicalEncounterProtocolNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    LabOrderStatus? status,
    String? diagnosis,
    LabOrderReason? orderReason,
    List<LabTestCode>? selectedTests,
    List<String>? selectedCustomTestIds,
    InfectionContext? infectionContext,
    String? infectionNotes,
    String? preoperativeNotes,
    String? ekgNotes,
    String? additionalNotes,
    String? templateId,
    String? templateName,
  }) {
    return LabOrder(
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
      diagnosis: diagnosis ?? this.diagnosis,
      orderReason: orderReason ?? this.orderReason,
      selectedTests: selectedTests ?? this.selectedTests,
      selectedCustomTestIds:
          selectedCustomTestIds ?? this.selectedCustomTestIds,
      infectionContext: infectionContext ?? this.infectionContext,
      infectionNotes: infectionNotes ?? this.infectionNotes,
      preoperativeNotes: preoperativeNotes ?? this.preoperativeNotes,
      ekgNotes: ekgNotes ?? this.ekgNotes,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
    );
  }

  String? get displayProtocolNumber {
    final value = clinicalEncounterProtocolNumber?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

String labOrderReasonLabel(LabOrderReason reason) {
  switch (reason) {
    case LabOrderReason.preoperatifHazirlik:
      return 'Pre-operatif hazırlık';
    case LabOrderReason.enfeksiyonSuphesi:
      return 'Enfeksiyon şüphesi';
    case LabOrderReason.postoperatif:
      return 'Post-operatif';
    case LabOrderReason.takip:
      return 'Takip';
  }
}

String labOrderStatusLabel(LabOrderStatus status) {
  switch (status) {
    case LabOrderStatus.taslak:
      return 'Taslak';
    case LabOrderStatus.istendi:
      return 'İstendi';
    case LabOrderStatus.tamamlandi:
      return 'Tamamlandı';
    case LabOrderStatus.iptal:
      return 'İptal';
  }
}
