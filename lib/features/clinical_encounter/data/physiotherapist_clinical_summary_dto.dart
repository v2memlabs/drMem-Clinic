import 'physiotherapist_clinical_summary_repository_failure.dart';

/// RPC `list/get_physiotherapist_clinical_summary` satırı — allowlist kolonlar.
///
/// `internal_doctor_note` ve `clinical_data` kasıtlı olarak okunmaz.
class PhysiotherapistClinicalSummaryDto {
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

  const PhysiotherapistClinicalSummaryDto({
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

  factory PhysiotherapistClinicalSummaryDto.fromMap(Map<String, dynamic> map) {
    final encounterId = _requireNonEmptyString(map['encounter_id'], 'encounter_id');
    final tenantId = _requireNonEmptyString(map['tenant_id'], 'tenant_id');
    final patientId = _requireNonEmptyString(map['patient_id'], 'patient_id');
    final encounterDate = _requireDateTime(map['encounter_date'], 'encounter_date');

    return PhysiotherapistClinicalSummaryDto(
      encounterId: encounterId,
      tenantId: tenantId,
      patientId: patientId,
      patientDisplayName: _optionalTrimmed(map['patient_display_name']) ?? '',
      encounterDate: encounterDate,
      bodyRegion: _optionalTrimmed(map['body_region']),
      side: _optionalTrimmed(map['side']),
      visitType: _optionalTrimmed(map['visit_type']),
      status: _optionalTrimmed(map['status']),
      physiotherapyReferral: _parseBool(map['physiotherapy_referral']),
      exerciseRecommendationShort:
          _optionalTrimmed(map['exercise_recommendation_short']),
      rehabPrecautionsShort: _optionalTrimmed(map['rehab_precautions_short']),
      weightBearingStatus: _optionalTrimmed(map['weight_bearing_status']),
      romLimitationShort: _optionalTrimmed(map['rom_limitation_short']),
      controlDate: _parseDateTime(map['control_date']),
      postOpContextShort: _optionalTrimmed(map['post_op_context_short']),
      ftrGoalShort: _optionalTrimmed(map['ftr_goal_short']),
      diagnosisSummary: _optionalTrimmed(map['diagnosis_summary']),
      treatmentPlanSummary: _optionalTrimmed(map['treatment_plan_summary']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
    // map['internal_doctor_note'] and map['clinical_data'] intentionally ignored
  }

  static String _requireNonEmptyString(dynamic value, String field) {
    final s = value?.toString().trim() ?? '';
    if (s.isEmpty) {
      throw PhysiotherapistClinicalSummaryRepositoryException(
        PhysiotherapistClinicalSummaryRepositoryFailure.invalidRow,
        cause: 'Missing $field',
      );
    }
    return s;
  }

  static DateTime _requireDateTime(dynamic value, String field) {
    final parsed = _parseDateTime(value);
    if (parsed == null) {
      throw PhysiotherapistClinicalSummaryRepositoryException(
        PhysiotherapistClinicalSummaryRepositoryFailure.invalidRow,
        cause: 'Missing $field',
      );
    }
    return parsed;
  }

  static String? _optionalTrimmed(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return false;
    final s = value.toString().trim().toLowerCase();
    return s == 'true' || s == 't' || s == '1' || s == 'yes';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s).toUtc();
    } catch (_) {
      return null;
    }
  }
}
