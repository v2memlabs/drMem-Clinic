import '../models/radiology_order.dart';
import 'radiology_order_list_refresh.dart';
import 'radiology_order_repository_failure.dart';
import 'radiology_order_repository_provider.dart';
import 'radiology_order_user_messages.dart';

abstract final class RadiologyOrderFormDataSource {
  static Future<RadiologyOrder> create(RadiologyOrder draft) async {
    try {
      final saved =
          await RadiologyOrderRepositoryProvider.asyncRepository.create(draft);
      RadiologyOrderListRefresh.markStale();
      return saved;
    } on RadiologyOrderRepositoryException catch (e) {
      throw RadiologyOrderFormException(
        RadiologyOrderUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const RadiologyOrderFormException(
        RadiologyOrderUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<RadiologyOrder> update(RadiologyOrder record) async {
    try {
      final saved =
          await RadiologyOrderRepositoryProvider.asyncRepository.update(record);
      RadiologyOrderListRefresh.markStale();
      return saved;
    } on RadiologyOrderRepositoryException catch (e) {
      throw RadiologyOrderFormException(
        RadiologyOrderUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const RadiologyOrderFormException(
        RadiologyOrderUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<RadiologyOrder?> loadForEdit(String id) async {
    try {
      return await RadiologyOrderRepositoryProvider.asyncRepository.getById(id);
    } catch (_) {
      return null;
    }
  }
}

class RadiologyOrderFormException implements Exception {
  final String message;

  const RadiologyOrderFormException(this.message);

  @override
  String toString() => message;
}
