import '../models/consent_record.dart';

abstract interface class AsyncConsentRepositoryContract {
  Future<List<ConsentRecord>> getAll();

  Future<List<ConsentRecord>> getByPatientId(String patientId);

  Future<ConsentRecord?> getById(String id);

  Future<List<ConsentRecord>> search(String query);

  Future<ConsentRecord> add(ConsentRecord consent);

  Future<ConsentRecord> update(ConsentRecord consent);

  Future<int> countPending();
}
