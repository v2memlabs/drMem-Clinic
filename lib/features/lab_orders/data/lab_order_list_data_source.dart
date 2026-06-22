import '../models/lab_order.dart';
import 'lab_order_list_load_result.dart';
import 'lab_order_repository_failure.dart';
import 'lab_order_repository_provider.dart';
import 'lab_order_user_messages.dart';

abstract final class LabOrderListDataSource {
  static Future<LabOrderListLoadResult> load({
    String? patientId,
    String? query,
    LabOrderStatus? statusFilter,
  }) async {
    try {
      final items = await LabOrderRepositoryProvider.asyncRepository.getFiltered(
        patientId: patientId,
        query: query,
        statusFilter: statusFilter,
      );
      return LabOrderListLoadResult.success(items);
    } on LabOrderRepositoryException catch (e) {
      return LabOrderListLoadResult.failure(
        LabOrderUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return LabOrderListLoadResult.failure(
        LabOrderUserMessages.genericLoadFailure,
      );
    }
  }
}
