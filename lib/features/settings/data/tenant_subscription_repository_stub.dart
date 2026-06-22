import '../models/tenant_subscription_summary.dart';
import 'tenant_subscription_repository.dart';

class TenantSubscriptionRepositoryStub implements TenantSubscriptionRepository {
  const TenantSubscriptionRepositoryStub();

  Never _notConfigured() => throw const TenantSubscriptionRepositoryException(
        TenantSubscriptionFailure.notConfigured,
        'Abonelik bilgileri şu anda kullanıma hazır değil.',
      );

  @override
  Future<TenantSubscriptionSummary> loadSummary() async => _notConfigured();
}
