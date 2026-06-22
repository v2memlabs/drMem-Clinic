import '../models/clinical_encounter.dart';
import 'async_clinical_encounter_repository_contract.dart';
import 'clinical_encounter_repository_failure.dart';

/// Supabase async muayene repository iskeleti — query yok, provider'a bağlı değil.
class SupabaseAsyncClinicalEncounterRepositoryStub
    implements AsyncClinicalEncounterRepositoryContract {
  const SupabaseAsyncClinicalEncounterRepositoryStub();

  Never _notConfigured() => throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.notConfigured,
      );

  @override
  Future<List<ClinicalEncounter>> getAll() async => _notConfigured();

  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async =>
      _notConfigured();

  @override
  Future<ClinicalEncounter?> getById(String id) async => _notConfigured();

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async =>
      _notConfigured();

  @override
  Future<List<ClinicalEncounter>> search(String query) async =>
      _notConfigured();

  @override
  Future<ClinicalEncounter> add(ClinicalEncounter encounter) async =>
      _notConfigured();

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async =>
      _notConfigured();

  @override
  Future<void> archiveEncounter(String id) async => _notConfigured();
}
