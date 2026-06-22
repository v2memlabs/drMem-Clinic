import '../models/radiology_order.dart';

class RadiologyOrderListLoadResult {
  final List<RadiologyOrder> items;
  final String? errorMessage;

  const RadiologyOrderListLoadResult._({
    this.items = const [],
    this.errorMessage,
  });

  factory RadiologyOrderListLoadResult.success(List<RadiologyOrder> items) {
    return RadiologyOrderListLoadResult._(items: items);
  }

  factory RadiologyOrderListLoadResult.failure(String message) {
    return RadiologyOrderListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
