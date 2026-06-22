import '../models/post_op_protocol.dart';
import 'post_op_protocol_repository_failure.dart';

abstract final class PostOpProtocolRemoteMapper {
  static const String table = 'post_op_protocols';

  static const String listSelectColumns =
      'id, tenant_id, patient_id, surgery_note_id, protocol_title, '
      'diagnosis_or_procedure_summary, phase, weight_bearing_status, '
      'range_of_motion_limits, brace_or_immobilization, wound_care_notes, '
      'medication_or_pain_control_notes, physiotherapy_instructions, '
      'exercise_restrictions, red_flags, control_date, return_to_sport_estimate, '
      'created_by, created_by_display, status, notes, created_at, '
      'patients(first_name, last_name)';

  static PostOpProtocol fromRow(Map<String, dynamic> row) {
    final patientName = _embeddedPatientFullName(row['patients']) ?? 'Hasta';
    final createdAt = _requireDateTime(row['created_at']);
    final controlDate = _optionalDate(row['control_date']);

    return PostOpProtocol(
      id: _requireString(row, 'id'),
      patientId: _requireString(row, 'patient_id'),
      patientName: patientName,
      surgeryNoteId: _optionalString(row['surgery_note_id']),
      createdAt: createdAt,
      protocolTitle:
          _optionalString(row['protocol_title']) ?? 'Post-op Protokol',
      diagnosisOrProcedureSummary:
          _optionalString(row['diagnosis_or_procedure_summary']) ?? '-',
      phase: _enumFromDb(PostOpPhase.values, row['phase']),
      weightBearingStatus: _optionalString(row['weight_bearing_status']) ?? '',
      rangeOfMotionLimits: _optionalString(row['range_of_motion_limits']) ?? '',
      braceOrImmobilization:
          _optionalString(row['brace_or_immobilization']) ?? '',
      woundCareNotes: _optionalString(row['wound_care_notes']) ?? '',
      medicationOrPainControlNotes:
          _optionalString(row['medication_or_pain_control_notes']) ?? '',
      physiotherapyInstructions:
          _optionalString(row['physiotherapy_instructions']) ?? '',
      exerciseRestrictions: _optionalString(row['exercise_restrictions']) ?? '',
      redFlags: _optionalString(row['red_flags']) ?? '',
      controlDate: controlDate,
      returnToSportEstimate:
          _optionalString(row['return_to_sport_estimate']) ?? '',
      createdBy: _optionalString(row['created_by_display']) ?? '',
      status: _enumFromDb(PostOpProtocolStatus.values, row['status']),
      notes: _optionalString(row['notes']) ?? '',
    );
  }

  static Map<String, dynamic> toInsertRow({
    required String tenantId,
    required PostOpProtocol protocol,
    String? createdByProfileId,
    String? createdByDisplay,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': protocol.patientId.trim(),
      if (protocol.surgeryNoteId?.trim().isNotEmpty == true)
        'surgery_note_id': protocol.surgeryNoteId!.trim(),
      'protocol_title': protocol.protocolTitle.trim(),
      'diagnosis_or_procedure_summary':
          protocol.diagnosisOrProcedureSummary.trim(),
      'phase': protocol.phase.name,
      'weight_bearing_status': protocol.weightBearingStatus.trim(),
      'range_of_motion_limits': protocol.rangeOfMotionLimits.trim(),
      'brace_or_immobilization': protocol.braceOrImmobilization.trim(),
      'wound_care_notes': protocol.woundCareNotes.trim(),
      'medication_or_pain_control_notes':
          protocol.medicationOrPainControlNotes.trim(),
      'physiotherapy_instructions': protocol.physiotherapyInstructions.trim(),
      'exercise_restrictions': protocol.exerciseRestrictions.trim(),
      'red_flags': protocol.redFlags.trim(),
      if (protocol.controlDate != null)
        'control_date': _dateOnly(protocol.controlDate!),
      'return_to_sport_estimate': protocol.returnToSportEstimate.trim(),
      if (createdByProfileId != null) 'created_by': createdByProfileId,
      'created_by_display': createdByDisplay?.trim().isNotEmpty == true
          ? createdByDisplay!.trim()
          : protocol.createdBy.trim(),
      'status': protocol.status.name,
      'notes': protocol.notes.trim(),
    };
  }

  static String _dateOnly(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _requireString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      throw const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.invalidRow,
      );
    }
    return value;
  }

  static String? _optionalString(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static DateTime _requireDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) {
      throw const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.invalidRow,
      );
    }
    return parsed;
  }

  static DateTime? _optionalDate(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String? _embeddedPatientFullName(dynamic value) {
    if (value is Map) {
      final first = value['first_name']?.toString().trim() ?? '';
      final last = value['last_name']?.toString().trim() ?? '';
      final name = '$first $last'.trim();
      return name.isEmpty ? null : name;
    }
    return null;
  }

  static T _enumFromDb<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) {
      throw const PostOpProtocolRepositoryException(
        PostOpProtocolRepositoryFailure.invalidRow,
      );
    }
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw const PostOpProtocolRepositoryException(
      PostOpProtocolRepositoryFailure.invalidRow,
    );
  }
}
