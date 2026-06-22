import '../models/payment_outstanding_patient_alert.dart';
import '../models/payment_record.dart';
import 'payment_outstanding_balance.dart';

abstract final class PaymentOutstandingAlerts {
  static List<PaymentOutstandingPatientAlert> fromRecords(
    List<PaymentRecord> records,
  ) {
    final grouped = <String, List<PaymentRecord>>{};
    for (final record in records) {
      if (!PaymentOutstandingBalance.hasOutstanding(record)) continue;
      grouped.putIfAbsent(record.patientId, () => []).add(record);
    }

    final alerts = grouped.entries.map((entry) {
      final list = entry.value;
      final remaining = PaymentOutstandingBalance.totalRemaining(list);
      final oldest = list
          .map((p) => p.transactionDate)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      return PaymentOutstandingPatientAlert(
        patientId: entry.key,
        patientName: list.first.patientName,
        totalRemaining: remaining,
        openRecordCount: list.length,
        oldestUnpaidDate: oldest,
      );
    }).toList(growable: false);

    alerts.sort((a, b) => b.totalRemaining.compareTo(a.totalRemaining));
    return alerts;
  }
}
