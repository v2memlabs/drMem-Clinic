/// Ödeme bildirimi repository hata sınıflandırması.
enum PaymentStaffNotificationRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class PaymentStaffNotificationRepositoryException implements Exception {
  final PaymentStaffNotificationRepositoryFailure reason;

  const PaymentStaffNotificationRepositoryException(this.reason);

  @override
  String toString() => 'PaymentStaffNotificationRepositoryException($reason)';
}
