import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_dto.dart';
import 'clinical_encounter_datetime_helper.dart';

/// `AssistantClinicalSummaryDto` → [AssistantClinicalSummary].
///
/// Allowlist projection only — no [ClinicalEncounter], no raw clinical_data.
abstract final class AssistantClinicalSummaryMapper {
  static const String defaultPatientDisplayName = 'Hasta';

  static AssistantClinicalSummary fromDto(AssistantClinicalSummaryDto dto) {
    return fromMapRow(dto);
  }

  static AssistantClinicalSummary fromMap(Map<String, dynamic> map) {
    return fromDto(AssistantClinicalSummaryDto.fromMap(map));
  }

  static AssistantClinicalSummary fromMapRow(AssistantClinicalSummaryDto dto) {
    final displayName = dto.patientDisplayName.trim();
    return AssistantClinicalSummary(
      encounterId: dto.encounterId,
      tenantId: dto.tenantId,
      patientId: dto.patientId,
      patientDisplayName:
          displayName.isEmpty ? defaultPatientDisplayName : displayName,
      encounterDate:
          ClinicalEncounterDateTimeHelper.toLocalForDisplay(dto.encounterDate),
      visitType: dto.visitType,
      status: dto.status,
      diagnosisSummary: dto.diagnosisSummary,
      operationalHeadline: dto.operationalHeadline,
      nextControlDate: dto.nextControlDate != null
          ? ClinicalEncounterDateTimeHelper.toLocalForDisplay(
              dto.nextControlDate!,
            )
          : null,
      appointmentId: dto.appointmentId,
      hasPhysiotherapyReferral: dto.hasPhysiotherapyReferral,
      updatedAt: dto.updatedAt != null
          ? ClinicalEncounterDateTimeHelper.toLocalForDisplay(dto.updatedAt!)
          : null,
    );
  }
}
