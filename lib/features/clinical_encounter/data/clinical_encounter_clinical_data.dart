import '../models/clinical_encounter.dart';
import '../models/clinical_treatment_approach.dart';
import 'clinical_body_region_mapping.dart';
import 'clinical_diagnosis_type_mapping.dart';
import 'clinical_encounter_datetime_helper.dart';
import 'clinical_side_mapping.dart';

/// `clinical_data` JSONB şema v1 — builder / parser.
///
/// [internalDoctorNote] bu yapıya **dahil edilmez**.
abstract final class ClinicalEncounterClinicalData {
  static const int schemaVersion = 1;

  static Map<String, dynamic> toMap(ClinicalEncounter encounter) {
    return {
      'schemaVersion': schemaVersion,
      'bodyRegion': ClinicalBodyRegionMapping.toDb(encounter.bodyRegion),
      'side': ClinicalSideMapping.toDb(encounter.side),
      'anamnesis': {
        'chiefComplaint': encounter.chiefComplaint,
        'complaintDuration': encounter.complaintDuration,
        'traumaHistory': encounter.traumaHistory,
        'painLocation': encounter.painLocation,
        'painCharacter': encounter.painCharacter,
        'vasScore': encounter.vasScore,
        'nightPain': encounter.nightPain,
        'activityRelation': encounter.activityRelation,
        'previousTreatments': encounter.previousTreatments,
        'medications': encounter.medications,
        'allergies': encounter.allergies,
        'comorbidities': encounter.comorbidities,
        'previousSurgeries': encounter.previousSurgeries,
        'generalNotes': encounter.generalNotes,
      },
      'sports': {
        'sportsSectionEnabled': encounter.sportsSectionEnabled,
        'sportBranch': encounter.sportBranch,
        'amateurOrProfessional': encounter.amateurOrProfessional,
        'trainingFrequency': encounter.trainingFrequency,
        'patientExpectation': encounter.patientExpectation,
        'returnToSportGoal': encounter.returnToSportGoal,
        'sportsRelated': encounter.sportsRelated,
        'returnToSportPlan': encounter.returnToSportPlan,
      },
      'examination': {
        'inspection': encounter.inspection,
        'palpation': encounter.palpation,
        'rangeOfMotion': encounter.rangeOfMotion,
        'muscleStrength': encounter.muscleStrength,
        'stabilityTests': encounter.stabilityTests,
        'specialTests': encounter.specialTests,
        'neurovascularStatus': encounter.neurovascularStatus,
        'comparisonWithOtherSide': encounter.comparisonWithOtherSide,
        'clinicalImpression': encounter.clinicalImpression,
      },
      'imaging': {
        'imagingSummary': encounter.imagingSummary,
        'imagingDoctorComment': encounter.imagingDoctorComment,
        'attachedFileNote': encounter.attachedFileNote,
      },
      'diagnosis': {
        'preliminaryDiagnosis': encounter.preliminaryDiagnosis,
        'finalDiagnosis': encounter.finalDiagnosis,
        'differentialDiagnosis': encounter.differentialDiagnosis,
        'type': ClinicalDiagnosisTypeMapping.toDb(encounter.diagnosisType),
        'icdCode': encounter.icdCode,
        'icdTitle': encounter.icdTitle,
      },
      'plan': {
        'planTitle': encounter.planTitle,
        'conservativeTreatment': encounter.conservativeTreatment,
        'medicationNotes': encounter.medicationNotes,
        'injectionOrProcedurePlan': encounter.injectionOrProcedurePlan,
        'physiotherapyReferral': encounter.physiotherapyReferral,
        'exerciseRecommendation': encounter.exerciseRecommendation,
        'imagingRequest': encounter.imagingRequest,
        'controlDate': _controlDateToJson(encounter.controlDate),
        'surgeryRecommendation': encounter.surgeryRecommendation,
        'patientInformationNote': encounter.patientInformationNote,
        'warningNotes': encounter.warningNotes,
        'orthosisNotes': encounter.orthosisNotes,
        'treatmentApproach':
            ClinicalTreatmentApproach.toDb(encounter.treatmentApproach),
      },
      'meta': {
        if (encounter.doctorName.trim().isNotEmpty)
          'doctorDisplayName': encounter.doctorName.trim(),
      },
    };
  }

  static ClinicalEncounterClinicalDataFields fromMap(dynamic value) {
    final map = _asMap(value);
    if (map.isEmpty) return ClinicalEncounterClinicalDataFields.empty();

    final anamnesis = _asMap(map['anamnesis']);
    final sports = _asMap(map['sports']);
    final examination = _asMap(map['examination']);
    final imaging = _asMap(map['imaging']);
    final diagnosis = _asMap(map['diagnosis']);
    final plan = _asMap(map['plan']);
    final meta = _asMap(map['meta']);

    return ClinicalEncounterClinicalDataFields(
      bodyRegion: ClinicalBodyRegionMapping.fromDb(map['bodyRegion'] as String?),
      side: ClinicalSideMapping.fromDb(map['side'] as String?),
      chiefComplaint: _str(anamnesis['chiefComplaint']),
      complaintDuration: _str(anamnesis['complaintDuration']),
      traumaHistory: _bool(anamnesis['traumaHistory']),
      painLocation: _str(anamnesis['painLocation']),
      painCharacter: _str(anamnesis['painCharacter']),
      vasScore: _int(anamnesis['vasScore']),
      nightPain: _bool(anamnesis['nightPain']),
      activityRelation: _str(anamnesis['activityRelation']),
      previousTreatments: _str(anamnesis['previousTreatments']),
      medications: _str(anamnesis['medications']),
      allergies: _str(anamnesis['allergies']),
      comorbidities: _str(anamnesis['comorbidities']),
      previousSurgeries: _str(anamnesis['previousSurgeries']),
      generalNotes: _str(anamnesis['generalNotes']),
      sportsSectionEnabled: _bool(sports['sportsSectionEnabled']),
      sportBranch: _str(sports['sportBranch']),
      amateurOrProfessional: _str(sports['amateurOrProfessional']),
      trainingFrequency: _str(sports['trainingFrequency']),
      patientExpectation: _str(sports['patientExpectation']),
      returnToSportGoal: _str(sports['returnToSportGoal']),
      sportsRelated: _bool(sports['sportsRelated']),
      returnToSportPlan: _str(sports['returnToSportPlan']),
      inspection: _str(examination['inspection']),
      palpation: _str(examination['palpation']),
      rangeOfMotion: _str(examination['rangeOfMotion']),
      muscleStrength: _str(examination['muscleStrength']),
      stabilityTests: _str(examination['stabilityTests']),
      specialTests: _str(examination['specialTests']),
      neurovascularStatus: _str(examination['neurovascularStatus']),
      comparisonWithOtherSide: _str(examination['comparisonWithOtherSide']),
      clinicalImpression: _str(examination['clinicalImpression']),
      imagingSummary: _str(imaging['imagingSummary']),
      imagingDoctorComment: _str(imaging['imagingDoctorComment']),
      attachedFileNote: _str(imaging['attachedFileNote']),
      preliminaryDiagnosis: _str(diagnosis['preliminaryDiagnosis']),
      finalDiagnosis: _str(diagnosis['finalDiagnosis']),
      differentialDiagnosis: _str(diagnosis['differentialDiagnosis']),
      diagnosisType:
          ClinicalDiagnosisTypeMapping.fromDb(diagnosis['type'] as String?),
      icdCode: _str(diagnosis['icdCode']),
      icdTitle: _str(diagnosis['icdTitle']),
      planTitle: _str(plan['planTitle']),
      conservativeTreatment: _str(plan['conservativeTreatment']),
      medicationNotes: _str(plan['medicationNotes']),
      injectionOrProcedurePlan: _str(plan['injectionOrProcedurePlan']),
      physiotherapyReferral: _bool(plan['physiotherapyReferral']),
      exerciseRecommendation: _str(plan['exerciseRecommendation']),
      imagingRequest: _str(plan['imagingRequest']),
      controlDate: _controlDateFromJson(plan['controlDate']),
      surgeryRecommendation: _str(plan['surgeryRecommendation']),
      patientInformationNote: _str(plan['patientInformationNote']),
      warningNotes: _str(plan['warningNotes']),
      orthosisNotes: _str(plan['orthosisNotes']),
      treatmentApproach:
          ClinicalTreatmentApproach.fromDb(plan['treatmentApproach'] as String?),
      doctorDisplayName: _str(meta['doctorDisplayName']),
    );
  }

  static String? _controlDateToJson(DateTime? value) {
    if (value == null) return null;
    return ClinicalEncounterDateTimeHelper.toUtcIsoString(value);
  }

  static DateTime? _controlDateFromJson(dynamic value) {
    if (value == null) return null;
    try {
      return ClinicalEncounterDateTimeHelper.toLocalForDisplay(
        ClinicalEncounterDateTimeHelper.parseFromDb(value),
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  static String _str(dynamic value) => value?.toString() ?? '';

  static bool _bool(dynamic value) => value == true;

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

/// `clinical_data` parse sonucu — model alanlarına aktarım için.
class ClinicalEncounterClinicalDataFields {
  final ClinicalBodyRegion bodyRegion;
  final ClinicalSide side;
  final String chiefComplaint;
  final String complaintDuration;
  final bool traumaHistory;
  final String painLocation;
  final String painCharacter;
  final int vasScore;
  final bool nightPain;
  final String activityRelation;
  final String previousTreatments;
  final String medications;
  final String allergies;
  final String comorbidities;
  final String previousSurgeries;
  final String generalNotes;
  final bool sportsSectionEnabled;
  final String sportBranch;
  final String amateurOrProfessional;
  final String trainingFrequency;
  final String patientExpectation;
  final String returnToSportGoal;
  final bool sportsRelated;
  final String returnToSportPlan;
  final String inspection;
  final String palpation;
  final String rangeOfMotion;
  final String muscleStrength;
  final String stabilityTests;
  final String specialTests;
  final String neurovascularStatus;
  final String comparisonWithOtherSide;
  final String clinicalImpression;
  final String imagingSummary;
  final String imagingDoctorComment;
  final String attachedFileNote;
  final String preliminaryDiagnosis;
  final String finalDiagnosis;
  final String differentialDiagnosis;
  final ClinicalDiagnosisType diagnosisType;
  final String icdCode;
  final String icdTitle;
  final String planTitle;
  final String conservativeTreatment;
  final String medicationNotes;
  final String injectionOrProcedurePlan;
  final bool physiotherapyReferral;
  final String exerciseRecommendation;
  final String imagingRequest;
  final DateTime? controlDate;
  final String surgeryRecommendation;
  final String patientInformationNote;
  final String warningNotes;
  final String orthosisNotes;
  final ClinicalTreatmentApproach? treatmentApproach;
  final String doctorDisplayName;

  const ClinicalEncounterClinicalDataFields({
    required this.bodyRegion,
    required this.side,
    required this.chiefComplaint,
    required this.complaintDuration,
    required this.traumaHistory,
    required this.painLocation,
    required this.painCharacter,
    required this.vasScore,
    required this.nightPain,
    required this.activityRelation,
    required this.previousTreatments,
    required this.medications,
    required this.allergies,
    required this.comorbidities,
    required this.previousSurgeries,
    required this.generalNotes,
    required this.sportsSectionEnabled,
    required this.sportBranch,
    required this.amateurOrProfessional,
    required this.trainingFrequency,
    required this.patientExpectation,
    required this.returnToSportGoal,
    required this.sportsRelated,
    required this.returnToSportPlan,
    required this.inspection,
    required this.palpation,
    required this.rangeOfMotion,
    required this.muscleStrength,
    required this.stabilityTests,
    required this.specialTests,
    required this.neurovascularStatus,
    required this.comparisonWithOtherSide,
    required this.clinicalImpression,
    required this.imagingSummary,
    required this.imagingDoctorComment,
    required this.attachedFileNote,
    required this.preliminaryDiagnosis,
    required this.finalDiagnosis,
    required this.differentialDiagnosis,
    required this.diagnosisType,
    required this.icdCode,
    required this.icdTitle,
    required this.planTitle,
    required this.conservativeTreatment,
    required this.medicationNotes,
    required this.injectionOrProcedurePlan,
    required this.physiotherapyReferral,
    required this.exerciseRecommendation,
    required this.imagingRequest,
    required this.controlDate,
    required this.surgeryRecommendation,
    required this.patientInformationNote,
    required this.warningNotes,
    this.orthosisNotes = '',
    this.treatmentApproach,
    required this.doctorDisplayName,
  });

  factory ClinicalEncounterClinicalDataFields.empty() {
    return const ClinicalEncounterClinicalDataFields(
      bodyRegion: ClinicalBodyRegion.genel,
      side: ClinicalSide.uygunDegil,
      chiefComplaint: '',
      complaintDuration: '',
      traumaHistory: false,
      painLocation: '',
      painCharacter: '',
      vasScore: 0,
      nightPain: false,
      activityRelation: '',
      previousTreatments: '',
      medications: '',
      allergies: '',
      comorbidities: '',
      previousSurgeries: '',
      generalNotes: '',
      sportsSectionEnabled: false,
      sportBranch: '',
      amateurOrProfessional: '',
      trainingFrequency: '',
      patientExpectation: '',
      returnToSportGoal: '',
      sportsRelated: false,
      returnToSportPlan: '',
      inspection: '',
      palpation: '',
      rangeOfMotion: '',
      muscleStrength: '',
      stabilityTests: '',
      specialTests: '',
      neurovascularStatus: '',
      comparisonWithOtherSide: '',
      clinicalImpression: '',
      imagingSummary: '',
      imagingDoctorComment: '',
      attachedFileNote: '',
      preliminaryDiagnosis: '',
      finalDiagnosis: '',
      differentialDiagnosis: '',
      diagnosisType: ClinicalDiagnosisType.diger,
      icdCode: '',
      icdTitle: '',
      planTitle: '',
      conservativeTreatment: '',
      medicationNotes: '',
      injectionOrProcedurePlan: '',
      physiotherapyReferral: false,
      exerciseRecommendation: '',
      imagingRequest: '',
      controlDate: null,
      surgeryRecommendation: '',
      patientInformationNote: '',
      warningNotes: '',
      orthosisNotes: '',
      treatmentApproach: null,
      doctorDisplayName: '',
    );
  }
}
