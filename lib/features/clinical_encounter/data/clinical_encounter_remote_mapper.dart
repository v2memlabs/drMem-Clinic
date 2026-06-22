import '../models/clinical_encounter.dart';
import 'clinical_encounter_clinical_data.dart';
import 'clinical_encounter_datetime_helper.dart';
import 'clinical_encounter_remote_row.dart';
import 'clinical_encounter_status_mapping.dart';
import 'clinical_encounter_summary_builder.dart';
import 'clinical_visit_type_mapping.dart';

/// Supabase `clinical_encounters` satırı ↔ [ClinicalEncounter] (query yok).
abstract final class ClinicalEncounterRemoteMapper {
  static const String defaultPatientName = 'Hasta';

  static ClinicalEncounter fromRow(Map<String, dynamic> row) {
    return fromRemoteRow(ClinicalEncounterRemoteRow.fromMap(row));
  }

  static ClinicalEncounter fromRemoteRow(ClinicalEncounterRemoteRow row) {
    final data = ClinicalEncounterClinicalData.fromMap(row.clinicalData);
    final encounterLocal =
        ClinicalEncounterDateTimeHelper.toLocalForDisplay(row.encounterDate);
    final createdLocal = row.createdAt != null
        ? ClinicalEncounterDateTimeHelper.toLocalForDisplay(row.createdAt!)
        : encounterLocal;
    final updatedLocal = row.updatedAt != null
        ? ClinicalEncounterDateTimeHelper.toLocalForDisplay(row.updatedAt!)
        : createdLocal;

    final patientName = row.embeddedPatientFullName ?? defaultPatientName;
    final doctorName = data.doctorDisplayName.trim();
    final diagnosisSummary = row.diagnosisSummary?.trim() ?? '';
    final treatmentPlanSummary = row.treatmentPlanSummary?.trim() ?? '';

    return ClinicalEncounter(
      id: row.id ?? '',
      protocolNumber: row.protocolNumber ?? '',
      patientId: row.patientId,
      patientName: patientName,
      createdAt: createdLocal,
      updatedAt: updatedLocal,
      doctorName: doctorName,
      status: ClinicalEncounterStatusMapping.fromDb(row.status),
      visitType: ClinicalVisitTypeMapping.fromDb(row.visitType),
      bodyRegion: data.bodyRegion,
      side: data.side,
      chiefComplaint: data.chiefComplaint,
      complaintDuration: data.complaintDuration,
      traumaHistory: data.traumaHistory,
      painLocation: data.painLocation,
      painCharacter: data.painCharacter,
      vasScore: data.vasScore,
      nightPain: data.nightPain,
      activityRelation: data.activityRelation,
      previousTreatments: data.previousTreatments,
      medications: data.medications,
      allergies: data.allergies,
      comorbidities: data.comorbidities,
      previousSurgeries: data.previousSurgeries,
      generalNotes: data.generalNotes,
      sportsSectionEnabled: data.sportsSectionEnabled,
      sportBranch: data.sportBranch,
      amateurOrProfessional: data.amateurOrProfessional,
      trainingFrequency: data.trainingFrequency,
      patientExpectation: data.patientExpectation,
      returnToSportGoal: data.returnToSportGoal,
      sportsRelated: data.sportsRelated,
      returnToSportPlan: data.returnToSportPlan,
      inspection: data.inspection,
      palpation: data.palpation,
      rangeOfMotion: data.rangeOfMotion,
      muscleStrength: data.muscleStrength,
      stabilityTests: data.stabilityTests,
      specialTests: data.specialTests,
      neurovascularStatus: data.neurovascularStatus,
      comparisonWithOtherSide: data.comparisonWithOtherSide,
      clinicalImpression: data.clinicalImpression,
      imagingSummary: data.imagingSummary,
      imagingDoctorComment: data.imagingDoctorComment,
      attachedFileNote: data.attachedFileNote,
      preliminaryDiagnosis: data.preliminaryDiagnosis.trim().isNotEmpty
          ? data.preliminaryDiagnosis
          : diagnosisSummary,
      finalDiagnosis: data.finalDiagnosis,
      differentialDiagnosis: data.differentialDiagnosis,
      diagnosisType: data.diagnosisType,
      icdCode: data.icdCode,
      icdTitle: data.icdTitle,
      planTitle: data.planTitle.trim().isNotEmpty
          ? data.planTitle
          : treatmentPlanSummary,
      conservativeTreatment: data.conservativeTreatment,
      medicationNotes: data.medicationNotes,
      injectionOrProcedurePlan: data.injectionOrProcedurePlan,
      physiotherapyReferral: data.physiotherapyReferral,
      exerciseRecommendation: data.exerciseRecommendation,
      imagingRequest: data.imagingRequest,
      controlDate: data.controlDate,
      surgeryRecommendation: data.surgeryRecommendation,
      patientInformationNote: data.patientInformationNote,
      warningNotes: data.warningNotes,
      internalDoctorNote: row.internalDoctorNote ?? '',
      orthosisNotes: data.orthosisNotes,
      treatmentApproach: data.treatmentApproach,
      createdByProfileId: row.createdBy,
    );
  }

  /// Insert — `id` / timestamp / `deleted_at` gönderilmez; `tenant_id` scope'tan.
  static Map<String, dynamic> toInsertRow(
    ClinicalEncounter encounter, {
    required String tenantId,
    String? appointmentId,
    String? createdByProfileId,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': encounter.patientId,
      if (encounter.hasProtocolNumber)
        'protocol_number': encounter.protocolNumber.trim(),
      if (appointmentId != null && appointmentId.trim().isNotEmpty)
        'appointment_id': appointmentId.trim(),
      if (createdByProfileId != null && createdByProfileId.trim().isNotEmpty)
        'created_by': createdByProfileId.trim(),
      'encounter_date': ClinicalEncounterDateTimeHelper.toUtcIsoString(
        encounter.createdAt,
      ),
      'visit_type': ClinicalVisitTypeMapping.toDb(encounter.visitType),
      'status': ClinicalEncounterStatusMapping.toDb(encounter.status),
      'diagnosis_summary':
          ClinicalEncounterSummaryBuilder.diagnosisSummary(encounter),
      'treatment_plan_summary':
          ClinicalEncounterSummaryBuilder.treatmentPlanSummary(encounter),
      'clinical_data': ClinicalEncounterClinicalData.toMap(encounter),
      'internal_doctor_note': _internalNoteToDb(encounter.internalDoctorNote),
    };
  }

  /// Update — `id`, `tenant_id`, `patient_id`, `appointment_id`, `deleted_at` yok.
  static Map<String, dynamic> toUpdateRow(ClinicalEncounter encounter) {
    return {
      'encounter_date': ClinicalEncounterDateTimeHelper.toUtcIsoString(
        encounter.createdAt,
      ),
      'visit_type': ClinicalVisitTypeMapping.toDb(encounter.visitType),
      'status': ClinicalEncounterStatusMapping.toDb(encounter.status),
      'diagnosis_summary':
          ClinicalEncounterSummaryBuilder.diagnosisSummary(encounter),
      'treatment_plan_summary':
          ClinicalEncounterSummaryBuilder.treatmentPlanSummary(encounter),
      'clinical_data': ClinicalEncounterClinicalData.toMap(encounter),
      'internal_doctor_note': _internalNoteToDb(encounter.internalDoctorNote),
    };
  }

  /// Arşiv — soft delete.
  static Map<String, dynamic> toArchiveRow({DateTime? at}) {
    final when = (at ?? DateTime.now()).toUtc();
    return {'deleted_at': when.toIso8601String()};
  }

  static String? _internalNoteToDb(String note) {
    final t = note.trim();
    return t.isEmpty ? null : t;
  }
}
