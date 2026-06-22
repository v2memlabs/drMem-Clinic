import '../models/radiology_order.dart';
import 'async_radiology_order_repository_contract.dart';
import 'radiology_order_repository_failure.dart';

class SupabaseAsyncRadiologyOrderRepositoryStub
    implements AsyncRadiologyOrderRepositoryContract {
  const SupabaseAsyncRadiologyOrderRepositoryStub();

  static const _error = RadiologyOrderRepositoryException(
    RadiologyOrderRepositoryFailure.notConfigured,
  );

  @override
  Future<RadiologyOrder> create(RadiologyOrder order) async => throw _error;

  @override
  Future<void> delete(String id) async => throw _error;

  @override
  Future<List<RadiologyOrder>> getAll() async => throw _error;

  @override
  Future<RadiologyOrder?> getById(String id) async => throw _error;

  @override
  Future<List<RadiologyOrder>> getByPatientId(String patientId) async =>
      throw _error;

  @override
  Future<List<RadiologyOrder>> getFiltered({
    String? patientId,
    String? query,
    RadiologyOrderStatus? statusFilter,
  }) async =>
      throw _error;

  @override
  Future<RadiologyOrder> update(RadiologyOrder order) async => throw _error;
}
