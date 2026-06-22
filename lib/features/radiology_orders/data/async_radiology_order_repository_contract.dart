import '../models/radiology_order.dart';

abstract interface class AsyncRadiologyOrderRepositoryContract {
  Future<List<RadiologyOrder>> getAll();

  Future<List<RadiologyOrder>> getByPatientId(String patientId);

  Future<RadiologyOrder?> getById(String id);

  Future<List<RadiologyOrder>> getFiltered({
    String? patientId,
    String? query,
    RadiologyOrderStatus? statusFilter,
  });

  Future<RadiologyOrder> create(RadiologyOrder order);

  Future<RadiologyOrder> update(RadiologyOrder order);

  Future<void> delete(String id);
}
