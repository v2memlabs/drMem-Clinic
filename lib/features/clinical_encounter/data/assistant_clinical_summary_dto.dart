import 'assistant_clinical_summary_repository_failure.dart';

/// RPC `list/get_assistant_clinical_summary` satırı — allowlist kolonlar.
///
/// `internal_doctor_note` ve `clinical_data` kasıtlı olarak okunmaz.
class AssistantClinicalSummaryDto {
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

  const AssistantClinicalSummaryDto({
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

  factory AssistantClinicalSummaryDto.fromMap(Map<String, dynamic> map) {
    final encounterId = _requireNonEmptyString(map['encounter_id'], 'encounter_id');
    final tenantId = _requireNonEmptyString(map['tenant_id'], 'tenant_id');
    final patientId = _requireNonEmptyString(map['patient_id'], 'patient_id');
    final encounterDate = _requireDateTime(map['encounter_date'], 'encounter_date');

    return AssistantClinicalSummaryDto(
      encounterId: encounterId,
      tenantId: tenantId,
      patientId: patientId,
      patientDisplayName: _optionalTrimmed(map['patient_display_name']) ?? '',
      encounterDate: encounterDate,
      visitType: _optionalTrimmed(map['visit_type']),
      status: _optionalTrimmed(map['status']),
      diagnosisSummary: _optionalTrimmed(map['diagnosis_summary']),
      operationalHeadline: _optionalTrimmed(map['operational_headline']),
      nextControlDate: _parseDateTime(map['next_control_date']),
      appointmentId: _optionalTrimmed(map['appointment_id']),
      hasPhysiotherapyReferral: _parseBool(map['has_physiotherapy_referral']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
    // map['internal_doctor_note'] and map['clinical_data'] intentionally ignored
  }

  static String _requireNonEmptyString(dynamic value, String field) {
    final s = value?.toString().trim() ?? '';
    if (s.isEmpty) {
      throw AssistantClinicalSummaryRepositoryException(
        AssistantClinicalSummaryRepositoryFailure.invalidRow,
        cause: 'Missing $field',
      );
    }
    return s;
  }

  static DateTime _requireDateTime(dynamic value, String field) {
    final parsed = _parseDateTime(value);
    if (parsed == null) {
      throw AssistantClinicalSummaryRepositoryException(
        AssistantClinicalSummaryRepositoryFailure.invalidRow,
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
