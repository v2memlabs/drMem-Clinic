import '../models/payment_record.dart';
import 'payment_outstanding_balance.dart';

/// Operasyonel ödeme listesi — içinde bulunulan ay + açık bakiyeli kayıtlar.
abstract final class PaymentListPeriodFilter {
  static bool isInCurrentMonth(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    return local.year == now.year && local.month == now.month;
  }

  static bool isVisibleInOperationalList(PaymentRecord record) {
    return isInCurrentMonth(record.transactionDate) ||
        PaymentOutstandingBalance.hasOutstanding(record);
  }

  static List<PaymentRecord> applyOperationalScope({
    required List<PaymentRecord> records,
    required bool scopedToPatient,
  }) {
    if (scopedToPatient) return records;
    return records
        .where(isVisibleInOperationalList)
        .toList(growable: false);
  }

  static String currentMonthLabel() {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }
}
