import '../../../core/data/repository_registry.dart';
import '../models/lab_order_template.dart';

abstract final class LabOrderTemplateLookupDataSource {
  static Future<LabOrderTemplate?> findById(String templateId) async {
    final id = templateId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.labOrderTemplatesAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<LabOrderTemplate>> listAll() async {
    try {
      return await RepositoryRegistry.labOrderTemplatesAsync.getAll();
    } catch (_) {
      return const [];
    }
  }
}
