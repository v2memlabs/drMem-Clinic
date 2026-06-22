import '../models/lab_order.dart';
import 'async_lab_order_repository_contract.dart';
import 'lab_order_repository_failure.dart';

class SupabaseAsyncLabOrderRepositoryStub
    implements AsyncLabOrderRepositoryContract {
  const SupabaseAsyncLabOrderRepositoryStub();

  static const _error = LabOrderRepositoryException(
    LabOrderRepositoryFailure.notConfigured,
  );

  @override
  Future<LabOrder> create(LabOrder order) async => throw _error;

  @override
  Future<void> delete(String id) async => throw _error;

  @override
  Future<List<LabOrder>> getAll() async => throw _error;

  @override
  Future<LabOrder?> getById(String id) async => throw _error;

  @override
  Future<List<LabOrder>> getByPatientId(String patientId) async => throw _error;

  @override
  Future<List<LabOrder>> getFiltered({
    String? patientId,
    String? query,
    LabOrderStatus? statusFilter,
  }) async =>
      throw _error;

  @override
  Future<LabOrder> update(LabOrder order) async => throw _error;
}
