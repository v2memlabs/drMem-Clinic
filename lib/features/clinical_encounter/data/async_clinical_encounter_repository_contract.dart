import '../models/clinical_encounter.dart';

/// Remote muayene erişimi — async sözleşme (UI henüz bağlı değil).
///
/// `tenant_id` UI'dan gelmez — implementasyon [ActiveTenantContextStore] kullanır.
/// Yalnızca doctor_admin full-table path için tasarlanmıştır.
abstract interface class AsyncClinicalEncounterRepositoryContract {
  Future<List<ClinicalEncounter>> getAll();

  Future<List<ClinicalEncounter>> getByPatientId(String patientId);

  Future<ClinicalEncounter?> getById(String id);

  Future<ClinicalEncounter?> getLatestByPatientId(String patientId);

  Future<List<ClinicalEncounter>> search(String query);

  Future<ClinicalEncounter> add(ClinicalEncounter encounter);

  Future<ClinicalEncounter> update(ClinicalEncounter encounter);

  Future<void> archiveEncounter(String id);
}
