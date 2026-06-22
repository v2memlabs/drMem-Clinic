import '../models/payment_record.dart';

/// Açık bakiye hesabı — iptal/iade hariç.
abstract final class PaymentOutstandingBalance {
  static bool hasOutstanding(PaymentRecord record) {
    if (record.paymentStatus == PaymentStatus.iptal ||
        record.paymentStatus == PaymentStatus.iade) {
      return false;
    }
    return record.remainingAmount > 0.009;
  }

  static double totalRemaining(Iterable<PaymentRecord> records) {
    return records
        .where(hasOutstanding)
        .fold<double>(0, (sum, p) => sum + p.remainingAmount);
  }
}
