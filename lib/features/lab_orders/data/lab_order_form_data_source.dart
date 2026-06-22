import '../models/lab_order.dart';
import 'lab_order_list_refresh.dart';
import 'lab_order_repository_failure.dart';
import 'lab_order_repository_provider.dart';
import 'lab_order_user_messages.dart';

abstract final class LabOrderFormDataSource {
  static Future<LabOrder> create(LabOrder draft) async {
    try {
      final saved =
          await LabOrderRepositoryProvider.asyncRepository.create(draft);
      LabOrderListRefresh.markStale();
      return saved;
    } on LabOrderRepositoryException catch (e) {
      throw LabOrderFormException(
        LabOrderUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const LabOrderFormException(
        LabOrderUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<LabOrder> update(LabOrder record) async {
    try {
      final saved =
          await LabOrderRepositoryProvider.asyncRepository.update(record);
      LabOrderListRefresh.markStale();
      return saved;
    } on LabOrderRepositoryException catch (e) {
      throw LabOrderFormException(
        LabOrderUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const LabOrderFormException(
        LabOrderUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<LabOrder?> loadForEdit(String id) async {
    try {
      return await LabOrderRepositoryProvider.asyncRepository.getById(id);
    } catch (_) {
      return null;
    }
  }
}

class LabOrderFormException implements Exception {
  final String message;

  const LabOrderFormException(this.message);

  @override
  String toString() => message;
}
