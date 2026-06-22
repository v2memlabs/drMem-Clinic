import '../../../core/session/active_tenant_context_store.dart';
import '../models/assistant_clinical_summary.dart';
import '../models/clinical_encounter.dart';
import 'clinical_encounter_status_mapping.dart';
import 'clinical_encounter_summary_builder.dart';
import 'clinical_visit_type_mapping.dart';

/// Mock encounter → allowlist [AssistantClinicalSummary] (data layer only).
///
/// UI bu mapper'ı kullanmaz; [MockAssistantClinicalSummaryRepository] içindir.
abstract final class MockAssistantClinicalSummaryMapper {
  static AssistantClinicalSummary fromEncounter(ClinicalEncounter encounter) {
    final tenantId = ActiveTenantContextStore.current?.tenantId ?? 'mock-tenant';
    return AssistantClinicalSummary(
      encounterId: encounter.id,
      tenantId: tenantId,
      patientId: encounter.patientId,
      patientDisplayName: encounter.patientName.trim(),
      encounterDate: encounter.createdAt,
      visitType: ClinicalVisitTypeMapping.toDb(encounter.visitType),
      status: ClinicalEncounterStatusMapping.toDb(encounter.status),
      diagnosisSummary: ClinicalEncounterSummaryBuilder.diagnosisSummary(encounter),
      operationalHeadline: null,
      nextControlDate: encounter.controlDate,
      appointmentId: null,
      hasPhysiotherapyReferral: encounter.physiotherapyReferral,
      updatedAt: encounter.updatedAt,
    );
  }
}
