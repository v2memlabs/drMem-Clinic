import '../../../core/data/repository_registry.dart';
import '../models/payment_statistics_snapshot.dart';
import 'payment_list_user_messages.dart';
import 'payment_repository_failure.dart';

class PaymentStatisticsLoadResult {
  final PaymentStatisticsSnapshot? snapshot;
  final String? errorMessage;

  const PaymentStatisticsLoadResult._({
    this.snapshot,
    this.errorMessage,
  });

  factory PaymentStatisticsLoadResult.success(PaymentStatisticsSnapshot snapshot) {
    return PaymentStatisticsLoadResult._(snapshot: snapshot);
  }

  factory PaymentStatisticsLoadResult.failure(String message) {
    return PaymentStatisticsLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class PaymentStatisticsDataSource {
  static Future<PaymentStatisticsLoadResult> load({
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  }) async {
    try {
      final snapshot = await RepositoryRegistry.paymentsAsync.loadStatistics(
        scope: scope,
        year: year,
        month: month,
      );
      return PaymentStatisticsLoadResult.success(snapshot);
    } on PaymentRepositoryException catch (e) {
      return PaymentStatisticsLoadResult.failure(
        PaymentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PaymentStatisticsLoadResult.failure(
        PaymentListUserMessages.genericLoadFailure,
      );
    }
  }
}
