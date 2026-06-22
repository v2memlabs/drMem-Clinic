import '../models/lab_order.dart';
import 'async_lab_order_repository_contract.dart';
import 'lab_order_repository.dart';

class MockAsyncLabOrderRepositoryAdapter
    implements AsyncLabOrderRepositoryContract {
  LabOrderRepository get _sync => LabOrderRepository.instance;

  @override
  Future<LabOrder> create(LabOrder order) async {
    _sync.add(order);
    return order;
  }

  @override
  Future<void> delete(String id) async {
    _sync.delete(id);
  }

  @override
  Future<List<LabOrder>> getAll() async => _sync.getAll();

  @override
  Future<LabOrder?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<LabOrder>> getByPatientId(String patientId) async =>
      _sync.getFiltered(patientId: patientId);

  @override
  Future<List<LabOrder>> getFiltered({
    String? patientId,
    String? query,
    LabOrderStatus? statusFilter,
  }) async {
    return _sync.getFiltered(
      patientId: patientId,
      query: query,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<LabOrder> update(LabOrder order) async {
    _sync.update(order);
    return order;
  }
}
