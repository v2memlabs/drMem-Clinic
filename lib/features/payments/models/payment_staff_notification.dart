/// Asistan ana ekranı — doktor (veya diğer roller) ödeme bildirimi.
class PaymentStaffNotification {
  final String id;
  final String paymentId;
  final String patientId;
  final String patientName;
  final String title;
  final String body;
  final String createdByRole;
  final String createdByDisplay;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? readByDisplay;

  const PaymentStaffNotification({
    required this.id,
    required this.paymentId,
    required this.patientId,
    required this.patientName,
    required this.title,
    required this.body,
    required this.createdByRole,
    required this.createdByDisplay,
    required this.createdAt,
    this.readAt,
    this.readByDisplay,
  });

  bool get isRead => readAt != null;

  PaymentStaffNotification markRead({
    required DateTime at,
    required String readBy,
  }) {
    return PaymentStaffNotification(
      id: id,
      paymentId: paymentId,
      patientId: patientId,
      patientName: patientName,
      title: title,
      body: body,
      createdByRole: createdByRole,
      createdByDisplay: createdByDisplay,
      createdAt: createdAt,
      readAt: at,
      readByDisplay: readBy,
    );
  }
}
