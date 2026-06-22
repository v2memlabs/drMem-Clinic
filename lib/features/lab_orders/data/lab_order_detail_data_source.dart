import '../models/lab_order.dart';
import 'lab_order_list_refresh.dart';
import 'lab_order_repository_failure.dart';
import 'lab_order_repository_provider.dart';
import 'lab_order_user_messages.dart';

class LabOrderDetailLoadResult {
  final LabOrder? order;
  final String? errorMessage;

  const LabOrderDetailLoadResult._({this.order, this.errorMessage});

  factory LabOrderDetailLoadResult.success(LabOrder order) {
    return LabOrderDetailLoadResult._(order: order);
  }

  factory LabOrderDetailLoadResult.failure(String message) {
    return LabOrderDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class LabOrderDetailDataSource {
  static Future<LabOrderDetailLoadResult> load(String id) async {
    try {
      final order = await LabOrderRepositoryProvider.asyncRepository.getById(id);
      if (order == null) {
        return LabOrderDetailLoadResult.failure(LabOrderUserMessages.notFound);
      }
      return LabOrderDetailLoadResult.success(order);
    } on LabOrderRepositoryException catch (e) {
      return LabOrderDetailLoadResult.failure(
        LabOrderUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return LabOrderDetailLoadResult.failure(
        LabOrderUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<String?> delete(String id) async {
    try {
      await LabOrderRepositoryProvider.asyncRepository.delete(id);
      LabOrderListRefresh.markStale();
      return null;
    } on LabOrderRepositoryException catch (e) {
      return LabOrderUserMessages.forFailure(e.reason);
    } catch (_) {
      return LabOrderUserMessages.genericDeleteFailure;
    }
  }
}
