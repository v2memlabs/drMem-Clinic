import '../models/lab_order_template.dart';
import 'mock_lab_order_templates.dart';

class LabOrderTemplateRepository {
  LabOrderTemplateRepository._();

  static final LabOrderTemplateRepository instance =
      LabOrderTemplateRepository._();

  List<LabOrderTemplate> getAll() => List.unmodifiable(mockLabOrderTemplates);

  LabOrderTemplate? getById(String id) {
    for (final item in mockLabOrderTemplates) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<LabOrderTemplate> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockLabOrderTemplates.where((t) {
      if (t.name.toLowerCase().contains(q)) return true;
      if ((t.description ?? '').toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  void add(LabOrderTemplate template) =>
      mockLabOrderTemplates.insert(0, template);

  void update(LabOrderTemplate template) {
    final index =
        mockLabOrderTemplates.indexWhere((t) => t.id == template.id);
    if (index >= 0) mockLabOrderTemplates[index] = template;
  }

  bool delete(String id) {
    final index = mockLabOrderTemplates.indexWhere((t) => t.id == id);
    if (index < 0) return false;
    mockLabOrderTemplates.removeAt(index);
    return true;
  }
}
