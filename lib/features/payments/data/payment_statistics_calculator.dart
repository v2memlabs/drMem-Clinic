import '../models/payment_record.dart';
import '../models/payment_statistics_snapshot.dart';
import 'payment_outstanding_balance.dart';

abstract final class PaymentStatisticsCalculator {
  static const _months = [
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

  static PaymentStatisticsSnapshot compute({
    required List<PaymentRecord> records,
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  }) {
    final inPeriod = records.where((record) {
      final local = record.transactionDate.toLocal();
      if (local.year != year) return false;
      if (scope == PaymentStatisticsScope.year) return true;
      return month != null && local.month == month;
    }).toList(growable: false);

    final patients = inPeriod.map((p) => p.patientId).toSet();
    final collectedByService = <ServiceType, double>{};
    var accrual = 0.0;
    var collected = 0.0;

    for (final record in inPeriod) {
      if (record.paymentStatus == PaymentStatus.iptal ||
          record.paymentStatus == PaymentStatus.iade) {
        continue;
      }
      accrual += record.totalAmount;
      collected += record.paidAmount;
      collectedByService.update(
        record.serviceType,
        (value) => value + record.paidAmount,
        ifAbsent: () => record.paidAmount,
      );
    }

    final outstandingAlerts = records
        .where(PaymentOutstandingBalance.hasOutstanding)
        .map((p) => p.patientId)
        .toSet();

    return PaymentStatisticsSnapshot(
      scope: scope,
      year: year,
      month: scope == PaymentStatisticsScope.month ? month : null,
      periodLabel: _periodLabel(scope: scope, year: year, month: month),
      totalAccrual: accrual,
      totalCollected: collected,
      openBalanceAllTime: PaymentOutstandingBalance.totalRemaining(records),
      paymentCount: inPeriod.length,
      patientCount: patients.length,
      outstandingPatientCount: outstandingAlerts.length,
      collectedByService: collectedByService,
    );
  }

  static String _periodLabel({
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  }) {
    if (scope == PaymentStatisticsScope.year) return '$year';
    if (month == null) return '$year';
    return '${_months[month - 1]} $year';
  }

  static List<int> recentYears({int count = 5}) {
    final now = DateTime.now().year;
    return List.generate(count, (index) => now - index);
  }

  static List<DateTime> recentMonths({int count = 24}) {
    final now = DateTime.now();
    return List.generate(count, (index) {
      return DateTime(now.year, now.month - index, 1);
    });
  }

  static String monthYearLabel(DateTime monthStart) {
    return '${_months[monthStart.month - 1]} ${monthStart.year}';
  }
}
