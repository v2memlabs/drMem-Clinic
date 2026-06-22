import '../models/lab_order_template.dart';

abstract interface class AsyncLabOrderTemplateRepositoryContract {
  Future<List<LabOrderTemplate>> getAll();

  Future<LabOrderTemplate?> getById(String id);

  Future<List<LabOrderTemplate>> search(String query);

  Future<LabOrderTemplate> create(LabOrderTemplate template);

  Future<LabOrderTemplate> update(LabOrderTemplate template);

  Future<void> delete(String id);
}
