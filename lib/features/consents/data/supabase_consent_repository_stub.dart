import '../models/consent_record.dart';
import 'async_consent_repository_contract.dart';
import 'consent_repository_failure.dart';

class SupabaseConsentRepositoryStub implements AsyncConsentRepositoryContract {
  const SupabaseConsentRepositoryStub();

  static Never _notReady() {
    throw const ConsentRepositoryException(
      ConsentRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<ConsentRecord>> getAll() async => _notReady();

  @override
  Future<List<ConsentRecord>> getByPatientId(String patientId) async =>
      _notReady();

  @override
  Future<ConsentRecord?> getById(String id) async => _notReady();

  @override
  Future<List<ConsentRecord>> search(String query) async => _notReady();

  @override
  Future<ConsentRecord> add(ConsentRecord consent) async => _notReady();

  @override
  Future<ConsentRecord> update(ConsentRecord consent) async => _notReady();

  @override
  Future<int> countPending() async => _notReady();
}
