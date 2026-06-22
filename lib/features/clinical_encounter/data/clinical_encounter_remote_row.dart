/// Supabase `clinical_encounters` tablo satırı — `supabase_flutter` bağımlılığı yok.
class ClinicalEncounterRemoteRow {
  final String? id;
  final String? protocolNumber;
  final String tenantId;
  final String patientId;
  final String? appointmentId;
  final DateTime encounterDate;
  final String? visitType;
  final String? status;
  final String? diagnosisSummary;
  final String? treatmentPlanSummary;
  final Map<String, dynamic> clinicalData;
  final String? internalDoctorNote;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Embed `patients(first_name, last_name)` (DB kolonu değil).
  final String? patientFirstName;
  final String? patientLastName;

  const ClinicalEncounterRemoteRow({
    this.id,
    this.protocolNumber,
    required this.tenantId,
    required this.patientId,
    this.appointmentId,
    required this.encounterDate,
    this.visitType,
    this.status,
    this.diagnosisSummary,
    this.treatmentPlanSummary,
    this.clinicalData = const {},
    this.internalDoctorNote,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.patientFirstName,
    this.patientLastName,
  });

  factory ClinicalEncounterRemoteRow.fromMap(Map<String, dynamic> map) {
    final embed = _parsePatientEmbed(map['patients']);
    return ClinicalEncounterRemoteRow(
      id: map['id'] as String?,
      protocolNumber: _nullableTrimmed(map['protocol_number']),
      tenantId: map['tenant_id'] as String? ?? '',
      patientId: map['patient_id'] as String? ?? '',
      appointmentId: map['appointment_id'] as String?,
      encounterDate: _requireEncounterDate(map['encounter_date']),
      visitType: _nullableTrimmed(map['visit_type']),
      status: _nullableTrimmed(map['status']),
      diagnosisSummary: _nullableTrimmed(map['diagnosis_summary']),
      treatmentPlanSummary: _nullableTrimmed(map['treatment_plan_summary']),
      clinicalData: _parseClinicalData(map['clinical_data']),
      internalDoctorNote: _nullableTrimmed(map['internal_doctor_note']),
      createdBy: map['created_by'] as String?,
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      deletedAt: _parseDateTime(map['deleted_at']),
      patientFirstName: embed?.$1,
      patientLastName: embed?.$2,
    );
  }

  String? get embeddedPatientFullName {
    final first = patientFirstName?.trim() ?? '';
    final last = patientLastName?.trim() ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? null : full;
  }

  static Map<String, dynamic> _parseClinicalData(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return {};
  }

  static (String, String)? _parsePatientEmbed(dynamic value) {
    if (value == null) return null;
    Map<String, dynamic>? map;
    if (value is Map<String, dynamic>) {
      map = value;
    } else if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) map = first;
    }
    if (map == null) return null;
    final fn = (map['first_name'] as String?)?.trim() ?? '';
    final ln = (map['last_name'] as String?)?.trim() ?? '';
    if (fn.isEmpty && ln.isEmpty) return null;
    return (fn, ln);
  }

  static String? _nullableTrimmed(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime _requireEncounterDate(dynamic value) {
    final parsed = _parseDateTime(value);
    if (parsed != null) return parsed;
    return DateTime.now().toUtc();
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
