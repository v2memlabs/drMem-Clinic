import '../models/tenant_subscription_summary.dart';

enum TenantSubscriptionFailure {
  forbidden,
  noActiveTenant,
  notConfigured,
  unknown,
}

class TenantSubscriptionRepositoryException implements Exception {
  const TenantSubscriptionRepositoryException(this.failure, this.message);

  final TenantSubscriptionFailure failure;
  final String message;

  @override
  String toString() => message;
}

abstract interface class TenantSubscriptionRepository {
  Future<TenantSubscriptionSummary> loadSummary();
}
