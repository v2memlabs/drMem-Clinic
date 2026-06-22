/// Assistant/Secretary güvenli klinik özet — allowlist projection.
///
/// [ClinicalEncounter] veya ham `clinical_data` yerine geçmez.
/// `internalDoctorNote` bu modelde yok ve olmamalı.
class AssistantClinicalSummary {
  final String encounterId;
  final String tenantId;
  final String patientId;
  final String patientDisplayName;
  final DateTime encounterDate;
  final String? visitType;
  final String? status;
  final String? diagnosisSummary;
  final String? operationalHeadline;
  final DateTime? nextControlDate;
  final String? appointmentId;
  final bool hasPhysiotherapyReferral;
  final DateTime? updatedAt;

  const AssistantClinicalSummary({
    required this.encounterId,
    required this.tenantId,
    required this.patientId,
    required this.patientDisplayName,
    required this.encounterDate,
    this.visitType,
    this.status,
    this.diagnosisSummary,
    this.operationalHeadline,
    this.nextControlDate,
    this.appointmentId,
    this.hasPhysiotherapyReferral = false,
    this.updatedAt,
  });
}
