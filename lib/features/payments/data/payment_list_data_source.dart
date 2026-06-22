import '../../../core/data/repository_registry.dart';
import '../models/payment_record.dart';
import 'payment_list_load_result.dart';
import 'payment_list_user_messages.dart';
import 'payment_repository_failure.dart';

abstract final class PaymentListDataSource {
  static Future<PaymentListLoadResult> load({
    String? patientId,
    required String query,
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
  }) async {
    try {
      final repo = RepositoryRegistry.paymentsAsync;
      final hasPatient = patientId != null && patientId.trim().isNotEmpty;
      final list = await repo.listFiltered(
        patientId: patientId,
        query: query,
        serviceTypeFilter: serviceTypeFilter,
        paymentStatusFilter: paymentStatusFilter,
        paymentMethodFilter: paymentMethodFilter,
        operationalScope: !hasPatient,
      );

      return PaymentListLoadResult.success(list);
    } on PaymentRepositoryException catch (e) {
      return PaymentListLoadResult.failure(
        PaymentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PaymentListLoadResult.failure(
        PaymentListUserMessages.genericLoadFailure,
      );
    }
  }
}
