import 'payment_record.dart';

enum PaymentStatisticsScope {
  month,
  year,
}

class PaymentStatisticsSnapshot {
  final PaymentStatisticsScope scope;
  final int year;
  final int? month;
  final String periodLabel;
  final double totalAccrual;
  final double totalCollected;
  final double openBalanceAllTime;
  final int paymentCount;
  final int patientCount;
  final int outstandingPatientCount;
  final Map<ServiceType, double> collectedByService;

  const PaymentStatisticsSnapshot({
    required this.scope,
    required this.year,
    required this.month,
    required this.periodLabel,
    required this.totalAccrual,
    required this.totalCollected,
    required this.openBalanceAllTime,
    required this.paymentCount,
    required this.patientCount,
    required this.outstandingPatientCount,
    required this.collectedByService,
  });

  double get collectionRate =>
      totalAccrual <= 0 ? 0 : (totalCollected / totalAccrual).clamp(0, 1);

  double get averageCollectedPerPatient =>
      patientCount <= 0 ? 0 : totalCollected / patientCount;
}
