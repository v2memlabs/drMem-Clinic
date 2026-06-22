import '../../../core/session/record_ownership_context.dart';
import '../models/clinical_encounter.dart';
import 'async_clinical_encounter_repository_contract.dart';
import 'clinical_encounter_repository.dart';
import 'clinical_encounter_repository_failure.dart';

/// Mock sync repository → async contract (anında tamamlanan Future).
///
/// Aktif UI bağlı değil; ileride provider switch için hazır.
class MockAsyncClinicalEncounterRepositoryAdapter
    implements AsyncClinicalEncounterRepositoryContract {
  ClinicalEncounterRepository get _sync => ClinicalEncounterRepository.instance;

  @override
  Future<List<ClinicalEncounter>> getAll() async => _sync.getAll();

  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<ClinicalEncounter?> getById(String id) async => _sync.getById(id);

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async =>
      _sync.getLatestByPatientId(patientId);

  @override
  Future<List<ClinicalEncounter>> search(String query) async =>
      _sync.search(query);

  @override
  Future<ClinicalEncounter> add(ClinicalEncounter encounter) async {
    final owned = ClinicalEncounter(
      id: encounter.id,
      protocolNumber: encounter.protocolNumber,
      patientId: encounter.patientId,
      patientName: encounter.patientName,
      createdAt: encounter.createdAt,
      updatedAt: encounter.updatedAt,
      doctorName: encounter.doctorName,
      status: encounter.status,
      visitType: encounter.visitType,
      bodyRegion: encounter.bodyRegion,
      side: encounter.side,
      chiefComplaint: encounter.chiefComplaint,
      complaintDuration: encounter.complaintDuration,
      traumaHistory: encounter.traumaHistory,
      painLocation: encounter.painLocation,
      painCharacter: encounter.painCharacter,
      vasScore: encounter.vasScore,
      nightPain: encounter.nightPain,
      activityRelation: encounter.activityRelation,
      previousTreatments: encounter.previousTreatments,
      medications: encounter.medications,
      allergies: encounter.allergies,
      comorbidities: encounter.comorbidities,
      previousSurgeries: encounter.previousSurgeries,
      generalNotes: encounter.generalNotes,
      sportsSectionEnabled: encounter.sportsSectionEnabled,
      sportBranch: encounter.sportBranch,
      amateurOrProfessional: encounter.amateurOrProfessional,
      trainingFrequency: encounter.trainingFrequency,
      patientExpectation: encounter.patientExpectation,
      returnToSportGoal: encounter.returnToSportGoal,
      sportsRelated: encounter.sportsRelated,
      returnToSportPlan: encounter.returnToSportPlan,
      inspection: encounter.inspection,
      palpation: encounter.palpation,
      rangeOfMotion: encounter.rangeOfMotion,
      muscleStrength: encounter.muscleStrength,
      stabilityTests: encounter.stabilityTests,
      specialTests: encounter.specialTests,
      neurovascularStatus: encounter.neurovascularStatus,
      comparisonWithOtherSide: encounter.comparisonWithOtherSide,
      clinicalImpression: encounter.clinicalImpression,
      imagingSummary: encounter.imagingSummary,
      imagingDoctorComment: encounter.imagingDoctorComment,
      attachedFileNote: encounter.attachedFileNote,
      preliminaryDiagnosis: encounter.preliminaryDiagnosis,
      finalDiagnosis: encounter.finalDiagnosis,
      differentialDiagnosis: encounter.differentialDiagnosis,
      diagnosisType: encounter.diagnosisType,
      icdCode: encounter.icdCode,
      icdTitle: encounter.icdTitle,
      planTitle: encounter.planTitle,
      conservativeTreatment: encounter.conservativeTreatment,
      medicationNotes: encounter.medicationNotes,
      injectionOrProcedurePlan: encounter.injectionOrProcedurePlan,
      physiotherapyReferral: encounter.physiotherapyReferral,
      exerciseRecommendation: encounter.exerciseRecommendation,
      imagingRequest: encounter.imagingRequest,
      controlDate: encounter.controlDate,
      surgeryRecommendation: encounter.surgeryRecommendation,
      patientInformationNote: encounter.patientInformationNote,
      warningNotes: encounter.warningNotes,
      internalDoctorNote: encounter.internalDoctorNote,
      orthosisNotes: encounter.orthosisNotes,
      treatmentApproach: encounter.treatmentApproach,
      createdByProfileId: RecordOwnershipContext.currentProfileId(),
    );
    _sync.add(owned);
    return owned;
  }

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async {
    final ok = _sync.update(encounter);
    if (!ok) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.notFound,
      );
    }
    return encounter;
  }

  @override
  Future<void> archiveEncounter(String id) async {
    // Mock'ta soft delete yok — remote v1 hazırlığı; no-op.
  }
}
