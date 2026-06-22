import '../models/physiotherapist_clinical_summary.dart';

/// Physiotherapist güvenli klinik özet — async sözleşme.
///
/// Allowlisted DB projection / RPC only. Do not substitute
/// [AsyncClinicalEncounterRepositoryContract] or full [ClinicalEncounter] here.
/// `tenant_id` UI'dan gelmez — implementasyon oturum tenant'ını kullanır.
abstract interface class PhysiotherapistClinicalSummaryRepository {
  Future<List<PhysiotherapistClinicalSummary>> listPhysiotherapistClinicalSummaries({
    String? patientId,
  });

  Future<PhysiotherapistClinicalSummary?> getPhysiotherapistClinicalSummary(
    String encounterId,
  );
}
