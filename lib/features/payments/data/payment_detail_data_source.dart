import '../../../core/data/repository_registry.dart';
import 'payment_detail_load_result.dart';
import 'payment_detail_user_messages.dart';
import 'payment_repository_failure.dart';

abstract final class PaymentDetailDataSource {
  static Future<PaymentDetailLoadResult> loadById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return PaymentDetailLoadResult.notFound();
    }

    try {
      final record =
          await RepositoryRegistry.paymentsAsync.getById(trimmed);
      if (record == null) {
        return PaymentDetailLoadResult.notFound();
      }
      return PaymentDetailLoadResult.success(record);
    } on PaymentRepositoryException catch (e) {
      if (e.reason == PaymentRepositoryFailure.notFound) {
        return PaymentDetailLoadResult.notFound();
      }
      return PaymentDetailLoadResult.failure(
        PaymentDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PaymentDetailLoadResult.failure(
        PaymentDetailUserMessages.genericLoadFailure,
      );
    }
  }
}
