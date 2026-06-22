import 'lab_order.dart';
import 'lab_test_catalog.dart';

class LabOrderTemplate {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<LabTestCode> selectedTests;
  final List<String> selectedCustomTestIds;
  final LabOrderReason defaultOrderReason;
  final String? defaultDiagnosis;
  final InfectionContext defaultInfectionContext;
  final String? preoperativeNotes;
  final String? ekgNotes;
  final String? additionalNotes;

  const LabOrderTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    required this.selectedTests,
    this.selectedCustomTestIds = const [],
    this.defaultOrderReason = LabOrderReason.preoperatifHazirlik,
    this.defaultDiagnosis,
    this.defaultInfectionContext = InfectionContext.yok,
    this.preoperativeNotes,
    this.ekgNotes,
    this.additionalNotes,
  });

  LabOrderTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LabTestCode>? selectedTests,
    List<String>? selectedCustomTestIds,
    LabOrderReason? defaultOrderReason,
    String? defaultDiagnosis,
    InfectionContext? defaultInfectionContext,
    String? preoperativeNotes,
    String? ekgNotes,
    String? additionalNotes,
  }) {
    return LabOrderTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      selectedTests: selectedTests ?? this.selectedTests,
      selectedCustomTestIds:
          selectedCustomTestIds ?? this.selectedCustomTestIds,
      defaultOrderReason: defaultOrderReason ?? this.defaultOrderReason,
      defaultDiagnosis: defaultDiagnosis ?? this.defaultDiagnosis,
      defaultInfectionContext:
          defaultInfectionContext ?? this.defaultInfectionContext,
      preoperativeNotes: preoperativeNotes ?? this.preoperativeNotes,
      ekgNotes: ekgNotes ?? this.ekgNotes,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}
