import '../models/consent_record.dart';
import 'async_consent_repository_contract.dart';
import 'consent_repository.dart';

class MockAsyncConsentRepositoryAdapter implements AsyncConsentRepositoryContract {
  ConsentRepository get _sync => ConsentRepository.instance;

  @override
  Future<List<ConsentRecord>> getAll() async => _sync.getAll();

  @override
  Future<List<ConsentRecord>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<ConsentRecord?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<ConsentRecord>> search(String query) async => _sync.search(query);

  @override
  Future<ConsentRecord> add(ConsentRecord consent) async {
    _sync.add(consent);
    return consent;
  }

  @override
  Future<ConsentRecord> update(ConsentRecord consent) async {
    _sync.update(consent);
    return consent;
  }

  @override
  Future<int> countPending() async =>
      _sync.getAll().where((c) => c.status == ConsentStatus.bekliyor).length;
}
