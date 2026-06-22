import '../models/radiology_order.dart';
import 'radiology_order_list_refresh.dart';
import 'radiology_order_repository_failure.dart';
import 'radiology_order_repository_provider.dart';
import 'radiology_order_user_messages.dart';

class RadiologyOrderDetailLoadResult {
  final RadiologyOrder? order;
  final String? errorMessage;

  const RadiologyOrderDetailLoadResult._({
    this.order,
    this.errorMessage,
  });

  factory RadiologyOrderDetailLoadResult.success(RadiologyOrder order) {
    return RadiologyOrderDetailLoadResult._(order: order);
  }

  factory RadiologyOrderDetailLoadResult.failure(String message) {
    return RadiologyOrderDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class RadiologyOrderDetailDataSource {
  static Future<RadiologyOrderDetailLoadResult> load(String id) async {
    try {
      final order =
          await RadiologyOrderRepositoryProvider.asyncRepository.getById(id);
      if (order == null) {
        return RadiologyOrderDetailLoadResult.failure(
          RadiologyOrderUserMessages.notFound,
        );
      }
      return RadiologyOrderDetailLoadResult.success(order);
    } on RadiologyOrderRepositoryException catch (e) {
      return RadiologyOrderDetailLoadResult.failure(
        RadiologyOrderUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return RadiologyOrderDetailLoadResult.failure(
        RadiologyOrderUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<String?> delete(String id) async {
    try {
      await RadiologyOrderRepositoryProvider.asyncRepository.delete(id);
      RadiologyOrderListRefresh.markStale();
      return null;
    } on RadiologyOrderRepositoryException catch (e) {
      return RadiologyOrderUserMessages.forFailure(e.reason);
    } catch (_) {
      return RadiologyOrderUserMessages.genericDeleteFailure;
    }
  }
}
