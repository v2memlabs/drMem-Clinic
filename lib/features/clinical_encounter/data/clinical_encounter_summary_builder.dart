import '../models/clinical_encounter.dart';

/// Üst kolon `diagnosis_summary` / `treatment_plan_summary` üretimi.
abstract final class ClinicalEncounterSummaryBuilder {
  static String? diagnosisSummary(ClinicalEncounter encounter) {
    final finalDx = encounter.finalDiagnosis.trim();
    if (finalDx.isNotEmpty) return finalDx;
    final prelim = encounter.preliminaryDiagnosis.trim();
    if (prelim.isNotEmpty) return prelim;
    return null;
  }

  static String? treatmentPlanSummary(ClinicalEncounter encounter) {
    final conservative = encounter.conservativeTreatment.trim();
    if (conservative.isNotEmpty) return conservative;
    final title = encounter.planTitle.trim();
    if (title.isNotEmpty) return title;
    return null;
  }
}
