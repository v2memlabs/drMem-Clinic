import '../../../core/session/active_tenant_context_store.dart';
import '../models/clinical_encounter.dart';
import '../models/physiotherapist_clinical_summary.dart';
import 'clinical_body_region_mapping.dart';
import 'clinical_encounter_status_mapping.dart';
import 'clinical_encounter_summary_builder.dart';
import 'clinical_side_mapping.dart';
import 'clinical_visit_type_mapping.dart';

/// Mock encounter → allowlist [PhysiotherapistClinicalSummary] (data layer only).
abstract final class MockPhysiotherapistClinicalSummaryMapper {
  static PhysiotherapistClinicalSummary fromEncounter(ClinicalEncounter encounter) {
    final tenantId = ActiveTenantContextStore.current?.tenantId ?? 'mock-tenant';
    return PhysiotherapistClinicalSummary(
      encounterId: encounter.id,
      tenantId: tenantId,
      patientId: encounter.patientId,
      patientDisplayName: encounter.patientName.trim(),
      encounterDate: encounter.createdAt,
      bodyRegion: ClinicalBodyRegionMapping.toDb(encounter.bodyRegion),
      side: ClinicalSideMapping.toDb(encounter.side),
      visitType: ClinicalVisitTypeMapping.toDb(encounter.visitType),
      status: ClinicalEncounterStatusMapping.toDb(encounter.status),
      physiotherapyReferral: encounter.physiotherapyReferral,
      exerciseRecommendationShort: _truncate120(encounter.exerciseRecommendation),
      rehabPrecautionsShort: _truncate120(encounter.warningNotes),
      weightBearingStatus: null,
      romLimitationShort: _truncate120(encounter.rangeOfMotion),
      controlDate: encounter.controlDate,
      postOpContextShort: _truncate120(encounter.surgeryRecommendation),
      ftrGoalShort: _truncate120(encounter.returnToSportGoal),
      diagnosisSummary: ClinicalEncounterSummaryBuilder.diagnosisSummary(encounter),
      treatmentPlanSummary:
          ClinicalEncounterSummaryBuilder.treatmentPlanSummary(encounter) ??
              _nullableTrim(encounter.treatmentPlanSummary),
      updatedAt: encounter.updatedAt,
    );
  }

  static String? _truncate120(String value) {
    final t = value.trim();
    if (t.isEmpty) return null;
    if (t.length <= 120) return t;
    return '${t.substring(0, 120)}…';
  }

  static String? _nullableTrim(String value) {
    final t = value.trim();
    if (t.isEmpty || t == '-') return null;
    return t;
  }
}
