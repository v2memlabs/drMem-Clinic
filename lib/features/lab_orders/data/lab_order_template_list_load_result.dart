import '../models/lab_order_template.dart';

class LabOrderTemplateListLoadResult {
  final List<LabOrderTemplate> items;
  final String? errorMessage;

  const LabOrderTemplateListLoadResult._({
    this.items = const [],
    this.errorMessage,
  });

  factory LabOrderTemplateListLoadResult.success(
    List<LabOrderTemplate> items,
  ) {
    return LabOrderTemplateListLoadResult._(items: items);
  }

  factory LabOrderTemplateListLoadResult.failure(String message) {
    return LabOrderTemplateListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
