/// Physiotherapist güvenli klinik özet — allowlist projection (FTR/rehab bağlamı).
///
/// [ClinicalEncounter] veya ham `clinical_data` yerine geçmez.
/// `internalDoctorNote` bu modelde yok ve olmamalı.
class PhysiotherapistClinicalSummary {
  final String encounterId;
  final String tenantId;
  final String patientId;
  final String patientDisplayName;
  final DateTime encounterDate;
  final String? bodyRegion;
  final String? side;
  final String? visitType;
  final String? status;
  final bool physiotherapyReferral;
  final String? exerciseRecommendationShort;
  final String? rehabPrecautionsShort;
  final String? weightBearingStatus;
  final String? romLimitationShort;
  final DateTime? controlDate;
  final String? postOpContextShort;
  final String? ftrGoalShort;
  final String? diagnosisSummary;
  final String? treatmentPlanSummary;
  final DateTime? updatedAt;

  const PhysiotherapistClinicalSummary({
    required this.encounterId,
    required this.tenantId,
    required this.patientId,
    required this.patientDisplayName,
    required this.encounterDate,
    this.bodyRegion,
    this.side,
    this.visitType,
    this.status,
    this.physiotherapyReferral = false,
    this.exerciseRecommendationShort,
    this.rehabPrecautionsShort,
    this.weightBearingStatus,
    this.romLimitationShort,
    this.controlDate,
    this.postOpContextShort,
    this.ftrGoalShort,
    this.diagnosisSummary,
    this.treatmentPlanSummary,
    this.updatedAt,
  });
}
