import '../models/lab_order.dart';

abstract interface class AsyncLabOrderRepositoryContract {
  Future<List<LabOrder>> getAll();

  Future<List<LabOrder>> getByPatientId(String patientId);

  Future<LabOrder?> getById(String id);

  Future<List<LabOrder>> getFiltered({
    String? patientId,
    String? query,
    LabOrderStatus? statusFilter,
  });

  Future<LabOrder> create(LabOrder order);

  Future<LabOrder> update(LabOrder order);

  Future<void> delete(String id);
}
