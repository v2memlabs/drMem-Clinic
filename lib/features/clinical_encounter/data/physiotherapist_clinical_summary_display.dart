import '../models/clinical_encounter.dart';
import '../models/physiotherapist_clinical_summary.dart';
import 'clinical_body_region_mapping.dart';
import 'clinical_encounter_status_mapping.dart';
import 'clinical_side_mapping.dart';
import 'clinical_visit_type_mapping.dart';

/// FTR güvenli özet — UI etiket/format (allowlist).
abstract final class PhysiotherapistClinicalSummaryDisplay {
  static String bodyRegionLabel(String? bodyRegion) {
    return ClinicalBodyRegionMapping.fromDb(bodyRegion).label;
  }

  static String sideLabel(String? side) {
    return ClinicalSideMapping.fromDb(side).label;
  }

  static String visitTypeLabel(String? visitType) {
    return ClinicalVisitTypeMapping.fromDb(visitType).label;
  }

  static String statusLabel(String? status) {
    return ClinicalEncounterStatusMapping.fromDb(status).label;
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  static String? formatOptionalDate(DateTime? date) {
    if (date == null) return null;
    return formatDate(date);
  }

  static String? displayOptional(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return null;
    return t;
  }

  static String listSubtitle(PhysiotherapistClinicalSummary summary) {
    final dx = summary.diagnosisSummary?.trim() ?? '';
    if (dx.isNotEmpty) {
      return dx.length > 120 ? '${dx.substring(0, 120)}…' : dx;
    }
    final plan = summary.treatmentPlanSummary?.trim() ?? '';
    if (plan.isNotEmpty) {
      return plan.length > 120 ? '${plan.substring(0, 120)}…' : plan;
    }
    return 'Tanı özeti belirtilmedi';
  }

  static String? listMetaLine(PhysiotherapistClinicalSummary summary) {
    final physio = summary.physiotherapyReferral
        ? 'Fizyoterapi yönlendirildi'
        : 'Fizyoterapi yönlendirmesi yok';
    final plan = summary.treatmentPlanSummary?.trim() ?? '';
    if (plan.isEmpty) return physio;
    final shortPlan = plan.length > 80 ? '${plan.substring(0, 80)}…' : plan;
    return '$physio • Plan: $shortPlan';
  }

  static List<String> listChips(PhysiotherapistClinicalSummary summary) {
    return [
      '${bodyRegionLabel(summary.bodyRegion)} / ${sideLabel(summary.side)}',
      statusLabel(summary.status),
      summary.physiotherapyReferral ? 'FTR: Var' : 'FTR: Yok',
    ];
  }

  static bool matchesBodyRegionFilter(
    PhysiotherapistClinicalSummary summary,
    ClinicalBodyRegion? region,
  ) {
    if (region == null) return true;
    return summary.bodyRegion == ClinicalBodyRegionMapping.toDb(region);
  }

  static bool matchesStatusFilter(
    PhysiotherapistClinicalSummary summary,
    ClinicalEncounterStatus? status,
  ) {
    if (status == null) return true;
    return summary.status == ClinicalEncounterStatusMapping.toDb(status);
  }
}
