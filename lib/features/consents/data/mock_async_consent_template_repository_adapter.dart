import '../models/consent_template.dart';
import 'async_consent_template_repository_contract.dart';
import 'consent_repository_failure.dart';
import 'consent_template_repository.dart';

class MockAsyncConsentTemplateRepositoryAdapter
    implements AsyncConsentTemplateRepositoryContract {
  ConsentTemplateRepository get _sync => ConsentTemplateRepository.instance;

  @override
  Future<ConsentTemplate> add(ConsentTemplate template) async {
    _sync.add(template);
    return template;
  }

  @override
  Future<List<ConsentTemplate>> getAll() async => _sync.getAll();

  @override
  Future<ConsentTemplate?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<ConsentTemplate>> getFiltered({
    String? query,
    String? categoryFilter,
    bool activeOnly = false,
  }) async {
    return _sync.getFiltered(
      query: query,
      categoryFilter: categoryFilter,
      activeOnly: activeOnly,
    );
  }

  @override
  Future<ConsentTemplate> update(ConsentTemplate template) async {
    _sync.update(template);
    return template;
  }
}

class SupabaseConsentTemplateRepositoryStub
    implements AsyncConsentTemplateRepositoryContract {
  const SupabaseConsentTemplateRepositoryStub();

  static Never _notReady() {
    throw const ConsentRepositoryException(
      ConsentRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<ConsentTemplate> add(ConsentTemplate template) async => _notReady();

  @override
  Future<List<ConsentTemplate>> getAll() async => _notReady();

  @override
  Future<ConsentTemplate?> getById(String id) async => _notReady();

  @override
  Future<List<ConsentTemplate>> getFiltered({
    String? query,
    String? categoryFilter,
    bool activeOnly = false,
  }) async =>
      _notReady();

  @override
  Future<ConsentTemplate> update(ConsentTemplate template) async =>
      _notReady();
}
