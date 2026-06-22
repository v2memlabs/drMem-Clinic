import '../models/payment_record.dart';

class PaymentDetailLoadResult {
  final PaymentRecord? record;
  final String? errorMessage;
  final bool notFound;

  const PaymentDetailLoadResult._({
    this.record,
    this.errorMessage,
    this.notFound = false,
  });

  factory PaymentDetailLoadResult.success(PaymentRecord record) {
    return PaymentDetailLoadResult._(record: record);
  }

  factory PaymentDetailLoadResult.notFound() {
    return const PaymentDetailLoadResult._(notFound: true);
  }

  factory PaymentDetailLoadResult.failure(String message) {
    return PaymentDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
