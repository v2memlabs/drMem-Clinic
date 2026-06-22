import '../models/consent_template.dart';

abstract interface class AsyncConsentTemplateRepositoryContract {
  Future<List<ConsentTemplate>> getAll();

  Future<ConsentTemplate?> getById(String id);

  Future<List<ConsentTemplate>> getFiltered({
    String? query,
    String? categoryFilter,
    bool activeOnly = false,
  });

  Future<ConsentTemplate> add(ConsentTemplate template);

  Future<ConsentTemplate> update(ConsentTemplate template);
}
