/// Ödeme repository hata sınıflandırması.
enum PaymentRepositoryFailure {
  forbidden,
  notFound,
  noActiveTenant,
  notConfigured,
  network,
  invalidRow,
  unknown,
}

class PaymentRepositoryException implements Exception {
  final PaymentRepositoryFailure reason;

  const PaymentRepositoryException(this.reason);

  @override
  String toString() => 'PaymentRepositoryException($reason)';
}
