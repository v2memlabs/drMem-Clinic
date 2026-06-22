import '../models/radiology_order.dart';
import 'radiology_order_list_load_result.dart';
import 'radiology_order_repository_failure.dart';
import 'radiology_order_repository_provider.dart';
import 'radiology_order_user_messages.dart';

abstract final class RadiologyOrderListDataSource {
  static Future<RadiologyOrderListLoadResult> load({
    String? patientId,
    String? query,
    RadiologyOrderStatus? statusFilter,
  }) async {
    try {
      final items = await RadiologyOrderRepositoryProvider.asyncRepository
          .getFiltered(
        patientId: patientId,
        query: query,
        statusFilter: statusFilter,
      );
      return RadiologyOrderListLoadResult.success(items);
    } on RadiologyOrderRepositoryException catch (e) {
      return RadiologyOrderListLoadResult.failure(
        RadiologyOrderUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return RadiologyOrderListLoadResult.failure(
        RadiologyOrderUserMessages.genericLoadFailure,
      );
    }
  }
}
