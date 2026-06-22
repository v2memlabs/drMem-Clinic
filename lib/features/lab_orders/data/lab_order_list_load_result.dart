import '../models/lab_order.dart';

class LabOrderListLoadResult {
  final List<LabOrder> items;
  final String? errorMessage;

  const LabOrderListLoadResult._({
    this.items = const [],
    this.errorMessage,
  });

  factory LabOrderListLoadResult.success(List<LabOrder> items) {
    return LabOrderListLoadResult._(items: items);
  }

  factory LabOrderListLoadResult.failure(String message) {
    return LabOrderListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
