import '../models/lab_order_template.dart';
import 'async_lab_order_template_repository_contract.dart';
import 'lab_order_template_repository_failure.dart';

class SupabaseAsyncLabOrderTemplateRepositoryStub
    implements AsyncLabOrderTemplateRepositoryContract {
  const SupabaseAsyncLabOrderTemplateRepositoryStub();

  static const _error = LabOrderTemplateRepositoryException(
    LabOrderTemplateRepositoryFailure.notConfigured,
  );

  @override
  Future<LabOrderTemplate> create(LabOrderTemplate template) async =>
      throw _error;

  @override
  Future<void> delete(String id) async => throw _error;

  @override
  Future<List<LabOrderTemplate>> getAll() async => throw _error;

  @override
  Future<LabOrderTemplate?> getById(String id) async => throw _error;

  @override
  Future<List<LabOrderTemplate>> search(String query) async => throw _error;

  @override
  Future<LabOrderTemplate> update(LabOrderTemplate template) async =>
      throw _error;
}
