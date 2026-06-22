import '../models/consent_template.dart';
import 'mock_consent_templates.dart';

class ConsentTemplateRepository {
  ConsentTemplateRepository._();

  static final ConsentTemplateRepository instance = ConsentTemplateRepository._();

  List<ConsentTemplate> getAll() => List.unmodifiable(mockConsentTemplates);

  ConsentTemplate? getById(String id) {
    for (final t in mockConsentTemplates) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<ConsentTemplate> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockConsentTemplates.where((t) => _matchesQuery(t, q)).toList();
  }

  List<ConsentTemplate> getFiltered({
    String? query,
    String? categoryFilter,
    bool activeOnly = false,
  }) {
    var list = getAll();

    if (activeOnly) {
      list = list.where((t) => t.isActive).toList();
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      list = list.where((t) => t.category == categoryFilter).toList();
    }

    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => _matchesQuery(t, q)).toList();
    }

    return list;
  }

  void add(ConsentTemplate template) {
    mockConsentTemplates.insert(0, template);
  }

  void update(ConsentTemplate template) {
    final index = mockConsentTemplates.indexWhere((t) => t.id == template.id);
    if (index < 0) {
      add(template);
      return;
    }
    mockConsentTemplates[index] = template;
  }

  bool _matchesQuery(ConsentTemplate t, String q) {
    if (t.title.toLowerCase().contains(q)) return true;
    if (t.category.toLowerCase().contains(q)) return true;
    if (t.description.toLowerCase().contains(q)) return true;
    if (t.documentFileName.toLowerCase().contains(q)) return true;
    if ((t.notes ?? '').toLowerCase().contains(q)) return true;
    return false;
  }
}
