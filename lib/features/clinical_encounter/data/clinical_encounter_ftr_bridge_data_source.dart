import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/data/repository_registry.dart';
import '../models/clinical_encounter.dart';
import 'clinical_encounter_list_refresh.dart';

/// FTR referral create sonrası muayene `physiotherapyReferral` flag write-back.
///
/// Referral tablosu operasyonel SSOT kalır; bridge yalnız encounter flag senkronlar.
/// Hatalar swallow edilir — referral create başarısız olmaz.
abstract final class ClinicalEncounterFtrBridgeDataSource {
  static Future<void> syncReferralFlagAfterReferralCreate(
    String clinicalEncounterId,
  ) async {
    final id = clinicalEncounterId.trim();
    if (id.isEmpty) return;
    if (!AuthSession.canEditClinicalEncounters) return;

    try {
      final encounter =
          await RepositoryRegistry.clinicalEncountersAsync.getById(id);
      if (encounter == null) {
        if (kDebugMode) {
          debugPrint(
            'ClinicalEncounterFtrBridge: encounter not found for id=$id',
          );
        }
        return;
      }
      if (encounter.physiotherapyReferral) return;

      final updated = _encounterWithReferralFlagEnabled(encounter);
      await RepositoryRegistry.clinicalEncountersAsync.update(updated);
      ClinicalEncounterListRefresh.markStale();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'ClinicalEncounterFtrBridge: sync failed for encounter id=$id',
        );
        debugPrint('$e');
        debugPrint('$stackTrace');
      }
    }
  }
}

ClinicalEncounter _encounterWithReferralFlagEnabled(ClinicalEncounter e) {
  return ClinicalEncounter(
    id: e.id,
    patientId: e.patientId,
    patientName: e.patientName,
    createdAt: e.createdAt,
    updatedAt: DateTime.now(),
    doctorName: e.doctorName,
    status: e.status,
    visitType: e.visitType,
    bodyRegion: e.bodyRegion,
    side: e.side,
    chiefComplaint: e.chiefComplaint,
    complaintDuration: e.complaintDuration,
    traumaHistory: e.traumaHistory,
    painLocation: e.painLocation,
    painCharacter: e.painCharacter,
    vasScore: e.vasScore,
    nightPain: e.nightPain,
    activityRelation: e.activityRelation,
    previousTreatments: e.previousTreatments,
    medications: e.medications,
    allergies: e.allergies,
    comorbidities: e.comorbidities,
    previousSurgeries: e.previousSurgeries,
    generalNotes: e.generalNotes,
    sportsSectionEnabled: e.sportsSectionEnabled,
    sportBranch: e.sportBranch,
    amateurOrProfessional: e.amateurOrProfessional,
    trainingFrequency: e.trainingFrequency,
    patientExpectation: e.patientExpectation,
    returnToSportGoal: e.returnToSportGoal,
    sportsRelated: e.sportsRelated,
    returnToSportPlan: e.returnToSportPlan,
    inspection: e.inspection,
    palpation: e.palpation,
    rangeOfMotion: e.rangeOfMotion,
    muscleStrength: e.muscleStrength,
    stabilityTests: e.stabilityTests,
    specialTests: e.specialTests,
    neurovascularStatus: e.neurovascularStatus,
    comparisonWithOtherSide: e.comparisonWithOtherSide,
    clinicalImpression: e.clinicalImpression,
    imagingSummary: e.imagingSummary,
    imagingDoctorComment: e.imagingDoctorComment,
    attachedFileNote: e.attachedFileNote,
    preliminaryDiagnosis: e.preliminaryDiagnosis,
    finalDiagnosis: e.finalDiagnosis,
    differentialDiagnosis: e.differentialDiagnosis,
    diagnosisType: e.diagnosisType,
    icdCode: e.icdCode,
    icdTitle: e.icdTitle,
    planTitle: e.planTitle,
    conservativeTreatment: e.conservativeTreatment,
    medicationNotes: e.medicationNotes,
    injectionOrProcedurePlan: e.injectionOrProcedurePlan,
    physiotherapyReferral: true,
    exerciseRecommendation: e.exerciseRecommendation,
    imagingRequest: e.imagingRequest,
    controlDate: e.controlDate,
    surgeryRecommendation: e.surgeryRecommendation,
    patientInformationNote: e.patientInformationNote,
    warningNotes: e.warningNotes,
    internalDoctorNote: e.internalDoctorNote,
    orthosisNotes: e.orthosisNotes,
    treatmentApproach: e.treatmentApproach,
  );
}
