import '../models/physiotherapist_clinical_summary.dart';
import 'clinical_encounter_datetime_helper.dart';
import 'physiotherapist_clinical_summary_dto.dart';

/// `PhysiotherapistClinicalSummaryDto` → [PhysiotherapistClinicalSummary].
///
/// Allowlist projection only — no [ClinicalEncounter], no raw clinical_data.
abstract final class PhysiotherapistClinicalSummaryMapper {
  static const String defaultPatientDisplayName = 'Hasta';

  static PhysiotherapistClinicalSummary fromDto(
    PhysiotherapistClinicalSummaryDto dto,
  ) {
    return fromMapRow(dto);
  }

  static PhysiotherapistClinicalSummary fromMap(Map<String, dynamic> map) {
    return fromDto(PhysiotherapistClinicalSummaryDto.fromMap(map));
  }

  static PhysiotherapistClinicalSummary fromMapRow(
    PhysiotherapistClinicalSummaryDto dto,
  ) {
    final displayName = dto.patientDisplayName.trim();
    return PhysiotherapistClinicalSummary(
      encounterId: dto.encounterId,
      tenantId: dto.tenantId,
      patientId: dto.patientId,
      patientDisplayName:
          displayName.isEmpty ? defaultPatientDisplayName : displayName,
      encounterDate:
          ClinicalEncounterDateTimeHelper.toLocalForDisplay(dto.encounterDate),
      bodyRegion: dto.bodyRegion,
      side: dto.side,
      visitType: dto.visitType,
      status: dto.status,
      physiotherapyReferral: dto.physiotherapyReferral,
      exerciseRecommendationShort: dto.exerciseRecommendationShort,
      rehabPrecautionsShort: dto.rehabPrecautionsShort,
      weightBearingStatus: dto.weightBearingStatus,
      romLimitationShort: dto.romLimitationShort,
      controlDate: dto.controlDate != null
          ? ClinicalEncounterDateTimeHelper.toLocalForDisplay(dto.controlDate!)
          : null,
      postOpContextShort: dto.postOpContextShort,
      ftrGoalShort: dto.ftrGoalShort,
      diagnosisSummary: dto.diagnosisSummary,
      treatmentPlanSummary: dto.treatmentPlanSummary,
      updatedAt: dto.updatedAt != null
          ? ClinicalEncounterDateTimeHelper.toLocalForDisplay(dto.updatedAt!)
          : null,
    );
  }
}
