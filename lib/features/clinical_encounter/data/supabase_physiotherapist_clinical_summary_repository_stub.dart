import '../models/physiotherapist_clinical_summary.dart';
import 'physiotherapist_clinical_summary_repository.dart';
import 'physiotherapist_clinical_summary_repository_failure.dart';

/// Supabase physiotherapist summary RPC iskeleti — query yok, provider'a bağlı değil.
class SupabasePhysiotherapistClinicalSummaryRepositoryStub
    implements PhysiotherapistClinicalSummaryRepository {
  const SupabasePhysiotherapistClinicalSummaryRepositoryStub();

  Never _notConfigured() =>
      throw const PhysiotherapistClinicalSummaryRepositoryException(
        PhysiotherapistClinicalSummaryRepositoryFailure.notConfigured,
      );

  @override
  Future<List<PhysiotherapistClinicalSummary>>
      listPhysiotherapistClinicalSummaries({
    String? patientId,
  }) async =>
          _notConfigured();

  @override
  Future<PhysiotherapistClinicalSummary?> getPhysiotherapistClinicalSummary(
    String encounterId,
  ) async =>
      _notConfigured();
}
