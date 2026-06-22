import '../models/patient.dart';
import 'async_patient_repository_contract.dart';
import 'patient_repository_failure.dart';

/// Supabase async hasta repository iskeleti — query yok, provider'a bağlı değil.
class SupabaseAsyncPatientRepositoryStub
    implements AsyncPatientRepositoryContract {
  const SupabaseAsyncPatientRepositoryStub();

  Never _notConfigured() => throw const PatientRepositoryException(
        PatientRepositoryFailure.notConfigured,
      );

  @override
  Future<List<Patient>> getAll() async => _notConfigured();

  @override
  Future<List<Patient>> search(String query) async => _notConfigured();

  @override
  Future<PatientListPage> listPage({
    String query = '',
    PatientListPageCursor? after,
    int limit = 50,
  }) async =>
      _notConfigured();

  @override
  Future<Patient?> getById(String id) async => _notConfigured();

  @override
  Future<String> getNameById(String id) async => _notConfigured();

  @override
  Future<int> count() async => _notConfigured();

  @override
  Future<String> nextFileNumber() async => _notConfigured();

  @override
  Future<Patient> add(Patient patient) async => _notConfigured();

  @override
  Future<Patient> update(Patient patient) async => _notConfigured();

  @override
  Future<void> archivePatient(String id) async => _notConfigured();
}
