import '../models/lab_order_template.dart';
import 'async_lab_order_template_repository_contract.dart';
import 'lab_order_template_repository.dart';

class MockAsyncLabOrderTemplateRepositoryAdapter
    implements AsyncLabOrderTemplateRepositoryContract {
  LabOrderTemplateRepository get _sync => LabOrderTemplateRepository.instance;

  @override
  Future<LabOrderTemplate> create(LabOrderTemplate template) async {
    _sync.add(template);
    return template;
  }

  @override
  Future<void> delete(String id) async {
    _sync.delete(id);
  }

  @override
  Future<List<LabOrderTemplate>> getAll() async => _sync.getAll();

  @override
  Future<LabOrderTemplate?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<LabOrderTemplate>> search(String query) async =>
      _sync.search(query);

  @override
  Future<LabOrderTemplate> update(LabOrderTemplate template) async {
    _sync.update(template);
    return template;
  }
}
