import '../models/clinical_encounter.dart';
import '../models/clinical_treatment_approach.dart';
import 'clinical_encounter_form_section_id.dart';

/// Muayene form bölüm doluluk kontrolü — basit non-empty kuralları.
abstract final class ClinicalEncounterFormCompletion {
  static bool hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  static bool anyText(Iterable<String> values) =>
      values.any((v) => hasText(v));

  static bool isSectionFilled(
    String sectionId, {
    required bool showPrivateNoteSection,
    required String chiefComplaint,
    required String generalNotes,
    required String medications,
    required String complaintDuration,
    required String painLocation,
    required String painCharacter,
    required String activityRelation,
    required String previousTreatments,
    required String allergies,
    required String comorbidities,
    required String previousSurgeries,
    required bool traumaHistory,
    required bool nightPain,
    required bool sportsSectionEnabled,
    required String sportBranch,
    required String amateurOrProfessional,
    required String trainingFrequency,
    required String patientExpectation,
    required String returnToSportGoal,
    required String returnToSportPlan,
    required bool sportsRelated,
    required String inspection,
    required String palpation,
    required String rangeOfMotion,
    required String muscleStrength,
    required String stabilityTests,
    required String specialTests,
    required String neurovascularStatus,
    required String comparisonWithOtherSide,
    required String clinicalImpression,
    required String imagingSummary,
    required String imagingDoctorComment,
    required String attachedFileNote,
    required String preliminaryDiagnosis,
    required String finalDiagnosis,
    required String differentialDiagnosis,
    required String icdCode,
    required String planTitle,
    required String conservativeTreatment,
    required String medicationNotes,
    required String injectionOrProcedurePlan,
    required String orthosisNotes,
    required String surgeryRecommendation,
    required ClinicalTreatmentApproach? treatmentApproach,
    required bool physiotherapyReferral,
    required String exerciseRecommendation,
    required String imagingRequest,
    required DateTime? controlDate,
    required ClinicalEncounterStatus status,
    required String patientInformationNote,
    required String warningNotes,
    required String internalDoctorNote,
  }) {
    switch (sectionId) {
      case ClinicalEncounterFormSectionId.complaint:
        return traumaHistory ||
            nightPain ||
            sportsSectionEnabled ||
            sportsRelated ||
            anyText([
              chiefComplaint,
              generalNotes,
              medications,
              complaintDuration,
              painLocation,
              painCharacter,
              activityRelation,
              previousTreatments,
              allergies,
              comorbidities,
              previousSurgeries,
              sportBranch,
              amateurOrProfessional,
              trainingFrequency,
              patientExpectation,
              returnToSportGoal,
              returnToSportPlan,
            ]);
      case ClinicalEncounterFormSectionId.examination:
        return anyText([
          clinicalImpression,
          inspection,
          palpation,
          rangeOfMotion,
          muscleStrength,
          stabilityTests,
          specialTests,
          neurovascularStatus,
          comparisonWithOtherSide,
        ]);
      case ClinicalEncounterFormSectionId.imaging:
        return anyText([
          imagingSummary,
          imagingDoctorComment,
          attachedFileNote,
        ]);
      case ClinicalEncounterFormSectionId.diagnosis:
        return anyText([
          preliminaryDiagnosis,
          finalDiagnosis,
          differentialDiagnosis,
          icdCode,
        ]);
      case ClinicalEncounterFormSectionId.treatment:
        return treatmentApproach != null ||
            anyText([
              planTitle,
              conservativeTreatment,
              medicationNotes,
              injectionOrProcedurePlan,
              orthosisNotes,
              surgeryRecommendation,
            ]);
      case ClinicalEncounterFormSectionId.followUp:
        return physiotherapyReferral ||
            controlDate != null ||
            status != ClinicalEncounterStatus.taslak ||
            anyText([
              exerciseRecommendation,
              imagingRequest,
              patientInformationNote,
              warningNotes,
            ]);
      case ClinicalEncounterFormSectionId.privateNote:
        if (!showPrivateNoteSection) return false;
        return hasText(internalDoctorNote);
      default:
        return false;
    }
  }
}
