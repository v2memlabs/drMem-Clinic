import '../models/payment_record.dart';

class PaymentListLoadResult {
  final List<PaymentRecord> records;
  final String? errorMessage;

  const PaymentListLoadResult._({
    required this.records,
    this.errorMessage,
  });

  factory PaymentListLoadResult.success(List<PaymentRecord> records) {
    return PaymentListLoadResult._(records: records);
  }

  factory PaymentListLoadResult.failure(String message) {
    return PaymentListLoadResult._(
      records: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
