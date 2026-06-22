import '../models/assistant_clinical_summary.dart';

/// Assistant/Secretary güvenli klinik özet — async sözleşme.
///
/// Allowlisted DB projection / RPC only. Do not substitute
/// [AsyncClinicalEncounterRepositoryContract] or full [ClinicalEncounter] here.
/// `tenant_id` UI'dan gelmez — implementasyon oturum tenant'ını kullanır.
abstract interface class AssistantClinicalSummaryRepository {
  Future<List<AssistantClinicalSummary>> listAssistantClinicalSummaries({
    String? patientId,
  });

  Future<AssistantClinicalSummary?> getAssistantClinicalSummary(
    String encounterId,
  );
}
