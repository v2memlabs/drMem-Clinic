import '../models/radiology_order.dart';
import 'async_radiology_order_repository_contract.dart';
import 'radiology_order_repository.dart';

class MockAsyncRadiologyOrderRepositoryAdapter
    implements AsyncRadiologyOrderRepositoryContract {
  RadiologyOrderRepository get _sync => RadiologyOrderRepository.instance;

  @override
  Future<RadiologyOrder> create(RadiologyOrder order) async {
    _sync.add(order);
    return order;
  }

  @override
  Future<void> delete(String id) async {
    if (!_sync.delete(id)) {
      throw StateError('Radiology order not found: $id');
    }
  }

  @override
  Future<List<RadiologyOrder>> getAll() async => _sync.getAll();

  @override
  Future<RadiologyOrder?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<RadiologyOrder>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<List<RadiologyOrder>> getFiltered({
    String? patientId,
    String? query,
    RadiologyOrderStatus? statusFilter,
  }) async {
    return _sync.getFiltered(
      patientId: patientId,
      query: query,
      statusFilter: statusFilter,
    );
  }

  @override
  Future<RadiologyOrder> update(RadiologyOrder order) async {
    _sync.update(order);
    return order;
  }
}
