import '../models/prescription.dart';

class PrescriptionListLoadResult {
  final List<Prescription> items;
  final String? errorMessage;

  const PrescriptionListLoadResult._({
    this.items = const [],
    this.errorMessage,
  });

  factory PrescriptionListLoadResult.success(List<Prescription> items) {
    return PrescriptionListLoadResult._(items: items);
  }

  factory PrescriptionListLoadResult.failure(String message) {
    return PrescriptionListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
