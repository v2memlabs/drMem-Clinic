import '../models/clinical_encounter.dart';
import '../models/physiotherapist_clinical_summary.dart';
import 'physiotherapist_clinical_summary_display.dart';

/// FTR özet listesi — istemci tarafı arama/filtre (allowlist alanlar).
abstract final class PhysiotherapistClinicalSummaryListFilters {
  static List<PhysiotherapistClinicalSummary> apply(
    List<PhysiotherapistClinicalSummary> items, {
    required String search,
    ClinicalBodyRegion? regionFilter,
    ClinicalEncounterStatus? statusFilter,
  }) {
    var list = items.where((s) {
      return PhysiotherapistClinicalSummaryDisplay.matchesBodyRegionFilter(
            s,
            regionFilter,
          ) &&
          PhysiotherapistClinicalSummaryDisplay.matchesStatusFilter(
            s,
            statusFilter,
          );
    }).toList();

    final q = search.trim().toLowerCase();
    if (q.isEmpty) return list;

    return list.where((s) {
      if (s.patientDisplayName.toLowerCase().contains(q)) return true;
      final dx = s.diagnosisSummary?.toLowerCase() ?? '';
      if (dx.contains(q)) return true;
      final plan = s.treatmentPlanSummary?.toLowerCase() ?? '';
      if (plan.contains(q)) return true;
      final region =
          PhysiotherapistClinicalSummaryDisplay.bodyRegionLabel(s.bodyRegion)
              .toLowerCase();
      if (region.contains(q)) return true;
      final exercise = s.exerciseRecommendationShort?.toLowerCase() ?? '';
      if (exercise.contains(q)) return true;
      final rehab = s.rehabPrecautionsShort?.toLowerCase() ?? '';
      if (rehab.contains(q)) return true;
      final ftrGoal = s.ftrGoalShort?.toLowerCase() ?? '';
      if (ftrGoal.contains(q)) return true;
      return false;
    }).toList();
  }
}
