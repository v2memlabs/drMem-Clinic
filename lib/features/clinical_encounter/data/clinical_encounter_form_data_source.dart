import '../../../core/auth/auth_session.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/repository_registry.dart';
import '../../patients/data/patient_lookup_data_source.dart';
import '../../patients/models/patient.dart';
import '../models/clinical_encounter.dart';
import 'clinical_encounter_protocol_number_helper.dart';
import 'clinical_encounter_protocol_remote_data_source.dart';
import 'clinical_encounter_repository_failure.dart';

/// Muayene form — async create/update/load ([RepositoryRegistry.clinicalEncountersAsync]).
abstract final class ClinicalEncounterFormDataSource {
  static Future<ClinicalEncounter?> loadForEdit(String id) async {
    try {
      return await RepositoryRegistry.clinicalEncountersAsync.getById(id);
    } on ClinicalEncounterRepositoryException {
      rethrow;
    } catch (_) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.unknown,
      );
    }
  }

  static Future<ClinicalEncounter> create(ClinicalEncounter draft) async {
    _assertValidEncounterDate(draft.createdAt);
    if (AppBackendConfig.isSupabase &&
        !RepositoryRegistry.usesRemoteClinicalEncounters) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.notConfigured,
      );
    }

    var toAdd = _prepareCreateDraft(draft);
    if (!toAdd.hasProtocolNumber) {
      toAdd = await _assignProtocolNumber(toAdd);
    }

    try {
      return await _addWithProtocolRetry(toAdd);
    } on ClinicalEncounterRepositoryException {
      rethrow;
    } catch (_) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.unknown,
      );
    }
  }

  static Future<ClinicalEncounter> _addWithProtocolRetry(
    ClinicalEncounter encounter,
  ) async {
    var current = encounter;
    const maxAttempts = 4;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await RepositoryRegistry.clinicalEncountersAsync.add(current);
      } on ClinicalEncounterRepositoryException catch (e) {
        if (e.reason != ClinicalEncounterRepositoryFailure.invalidClinicalData ||
            attempt >= maxAttempts - 1) {
          rethrow;
        }
        current = await _assignProtocolNumber(current);
      }
    }

    throw const ClinicalEncounterRepositoryException(
      ClinicalEncounterRepositoryFailure.invalidClinicalData,
    );
  }

  static Future<ClinicalEncounter> update(ClinicalEncounter encounter) async {
    _assertValidEncounterDate(encounter.createdAt);
    try {
      return await RepositoryRegistry.clinicalEncountersAsync.update(encounter);
    } on ClinicalEncounterRepositoryException {
      rethrow;
    } on StateError {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.notFound,
      );
    } catch (_) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.unknown,
      );
    }
  }

  static Future<String> resolvePatientName({
    required String patientId,
    Patient? selectedPatient,
  }) async {
    return PatientLookupDataSource.resolveName(
      patientId: patientId,
      selectedPatient: selectedPatient,
    );
  }

  static Future<bool> patientExists(String patientId) async {
    return PatientLookupDataSource.exists(patientId);
  }

  static String defaultDoctorName() {
    final name = AuthSession.currentUser?.displayName.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Dr. Mehmet Yalçınozan';
  }

  static Future<ClinicalEncounter> _assignProtocolNumber(
    ClinicalEncounter draft,
  ) async {
    Iterable<String> existingNumbers = const [];

    if (RepositoryRegistry.usesRemoteClinicalEncounters) {
      final next = await ClinicalEncounterProtocolRemoteDataSource.nextForActiveTenant(
        year: draft.createdAt.year,
      );
      return _copyEncounter(
        draft,
        id: draft.id,
        protocolNumber: next,
      );
    } else if (AppBackendConfig.isMock) {
      final existing =
          await RepositoryRegistry.clinicalEncountersAsync.getAll();
      existingNumbers = existing.map((e) => e.protocolNumber);
    }

    final next = ClinicalEncounterProtocolNumberHelper.nextFromExisting(
      existingNumbers,
      year: draft.createdAt.year,
    );
    return _copyEncounter(
      draft,
      id: draft.id,
      protocolNumber: next,
    );
  }

  static ClinicalEncounter _prepareCreateDraft(ClinicalEncounter draft) {
    if (RepositoryRegistry.usesRemoteClinicalEncounters) {
      return _copyEncounter(draft, id: '');
    }

    if (draft.id.isEmpty) {
      return _copyEncounter(
        draft,
        id: 'ce${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    return draft;
  }

  static ClinicalEncounter _copyEncounter(
    ClinicalEncounter source, {
    required String id,
    String? protocolNumber,
  }) {
    return ClinicalEncounter(
      id: id,
      protocolNumber: protocolNumber ?? source.protocolNumber,
      patientId: source.patientId,
      patientName: source.patientName,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
      doctorName: source.doctorName,
      status: source.status,
      visitType: source.visitType,
      bodyRegion: source.bodyRegion,
      side: source.side,
      chiefComplaint: source.chiefComplaint,
      complaintDuration: source.complaintDuration,
      traumaHistory: source.traumaHistory,
      painLocation: source.painLocation,
      painCharacter: source.painCharacter,
      vasScore: source.vasScore,
      nightPain: source.nightPain,
      activityRelation: source.activityRelation,
      previousTreatments: source.previousTreatments,
      medications: source.medications,
      allergies: source.allergies,
      comorbidities: source.comorbidities,
      previousSurgeries: source.previousSurgeries,
      generalNotes: source.generalNotes,
      sportsSectionEnabled: source.sportsSectionEnabled,
      sportBranch: source.sportBranch,
      amateurOrProfessional: source.amateurOrProfessional,
      trainingFrequency: source.trainingFrequency,
      patientExpectation: source.patientExpectation,
      returnToSportGoal: source.returnToSportGoal,
      sportsRelated: source.sportsRelated,
      returnToSportPlan: source.returnToSportPlan,
      inspection: source.inspection,
      palpation: source.palpation,
      rangeOfMotion: source.rangeOfMotion,
      muscleStrength: source.muscleStrength,
      stabilityTests: source.stabilityTests,
      specialTests: source.specialTests,
      neurovascularStatus: source.neurovascularStatus,
      comparisonWithOtherSide: source.comparisonWithOtherSide,
      clinicalImpression: source.clinicalImpression,
      imagingSummary: source.imagingSummary,
      imagingDoctorComment: source.imagingDoctorComment,
      attachedFileNote: source.attachedFileNote,
      preliminaryDiagnosis: source.preliminaryDiagnosis,
      finalDiagnosis: source.finalDiagnosis,
      differentialDiagnosis: source.differentialDiagnosis,
      diagnosisType: source.diagnosisType,
      icdCode: source.icdCode,
      icdTitle: source.icdTitle,
      planTitle: source.planTitle,
      conservativeTreatment: source.conservativeTreatment,
      medicationNotes: source.medicationNotes,
      injectionOrProcedurePlan: source.injectionOrProcedurePlan,
      physiotherapyReferral: source.physiotherapyReferral,
      exerciseRecommendation: source.exerciseRecommendation,
      imagingRequest: source.imagingRequest,
      controlDate: source.controlDate,
      surgeryRecommendation: source.surgeryRecommendation,
      patientInformationNote: source.patientInformationNote,
      warningNotes: source.warningNotes,
      internalDoctorNote: source.internalDoctorNote,
      orthosisNotes: source.orthosisNotes,
      treatmentApproach: source.treatmentApproach,
    );
  }

  static void _assertValidEncounterDate(DateTime dateTime) {
    if (dateTime.year < 1900 || dateTime.year > 2100) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.invalidClinicalData,
      );
    }
  }
}
