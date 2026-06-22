class PaymentOutstandingPatientAlert {
  final String patientId;
  final String patientName;
  final double totalRemaining;
  final int openRecordCount;
  final DateTime oldestUnpaidDate;

  const PaymentOutstandingPatientAlert({
    required this.patientId,
    required this.patientName,
    required this.totalRemaining,
    required this.openRecordCount,
    required this.oldestUnpaidDate,
  });
}
