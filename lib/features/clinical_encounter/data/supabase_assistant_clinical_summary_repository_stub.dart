import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_repository.dart';
import 'assistant_clinical_summary_repository_failure.dart';

/// Supabase assistant summary RPC iskeleti — query yok, provider'a bağlı değil.
class SupabaseAssistantClinicalSummaryRepositoryStub
    implements AssistantClinicalSummaryRepository {
  const SupabaseAssistantClinicalSummaryRepositoryStub();

  Never _notConfigured() => throw const AssistantClinicalSummaryRepositoryException(
        AssistantClinicalSummaryRepositoryFailure.notConfigured,
      );

  @override
  Future<List<AssistantClinicalSummary>> listAssistantClinicalSummaries({
    String? patientId,
  }) async =>
      _notConfigured();

  @override
  Future<AssistantClinicalSummary?> getAssistantClinicalSummary(
    String encounterId,
  ) async =>
      _notConfigured();
}
