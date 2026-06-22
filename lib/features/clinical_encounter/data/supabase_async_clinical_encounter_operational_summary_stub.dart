import 'async_clinical_encounter_operational_summary_contract.dart';
import 'clinical_encounter_repository_failure.dart';

/// Supabase güvenli muayene özeti iskeleti — query yok, provider'a bağlı değil.
class SupabaseAsyncClinicalEncounterOperationalSummaryStub
    implements AsyncClinicalEncounterOperationalSummaryContract {
  const SupabaseAsyncClinicalEncounterOperationalSummaryStub();

  Never _notConfigured() => throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.notConfigured,
      );

  @override
  Future<List<Map<String, dynamic>>> listSummaries({String? patientId}) async =>
      _notConfigured();

  @override
  Future<Map<String, dynamic>?> getSummaryById(String id) async =>
      _notConfigured();
}
