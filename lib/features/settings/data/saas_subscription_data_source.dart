import '../models/tenant_subscription_summary.dart';
import 'tenant_subscription_repository.dart';
import 'tenant_subscription_repository_provider.dart';

class SaasSubscriptionLoadResult {
  final TenantSubscriptionSummary? summary;
  final String? errorMessage;

  const SaasSubscriptionLoadResult._({
    this.summary,
    this.errorMessage,
  });

  factory SaasSubscriptionLoadResult.success(TenantSubscriptionSummary summary) {
    return SaasSubscriptionLoadResult._(summary: summary);
  }

  factory SaasSubscriptionLoadResult.failure(String message) {
    return SaasSubscriptionLoadResult._(errorMessage: message);
  }
}

abstract final class SaasSubscriptionDataSource {
  static Future<SaasSubscriptionLoadResult> load() async {
    try {
      final summary =
          await TenantSubscriptionRepositoryProvider.repository.loadSummary();
      return SaasSubscriptionLoadResult.success(summary);
    } on TenantSubscriptionRepositoryException catch (e) {
      return SaasSubscriptionLoadResult.failure(e.message);
    } catch (_) {
      return SaasSubscriptionLoadResult.failure(
        'Abonelik bilgileri yüklenemedi.',
      );
    }
  }
}
