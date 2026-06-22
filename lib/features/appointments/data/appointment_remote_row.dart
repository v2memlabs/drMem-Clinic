/// Supabase `appointments` tablo satırı — `supabase_flutter` bağımlılığı yok.
class AppointmentRemoteRow {
  final String? id;
  final String tenantId;
  final String patientId;
  final DateTime appointmentAt;
  final String status;
  final String? appointmentType;
  final String? notes;
  final String? createdBy;
  final String? assignedDoctorProfileId;
  final String? assignedPhysiotherapistProfileId;
  final String? assignedDoctorDisplayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Embed `patients(first_name, last_name)` sonucu (DB kolonu değil).
  final String? patientFirstName;
  final String? patientLastName;
  final String? patientFileNumber;

  const AppointmentRemoteRow({
    this.id,
    required this.tenantId,
    required this.patientId,
    required this.appointmentAt,
    required this.status,
    this.appointmentType,
    this.notes,
    this.createdBy,
    this.assignedDoctorProfileId,
    this.assignedPhysiotherapistProfileId,
    this.assignedDoctorDisplayName,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.patientFirstName,
    this.patientLastName,
    this.patientFileNumber,
  });

  factory AppointmentRemoteRow.fromMap(Map<String, dynamic> map) {
    final embed = _parsePatientEmbed(map['patients']);
    return AppointmentRemoteRow(
      id: map['id'] as String?,
      tenantId: map['tenant_id'] as String? ?? '',
      patientId: map['patient_id'] as String? ?? '',
      appointmentAt: _requireAppointmentAt(map['appointment_at']),
      status: (map['status'] as String?)?.trim() ?? '',
      appointmentType: _nullableTrimmed(map['appointment_type']),
      notes: _nullableTrimmed(map['notes']),
      createdBy: map['created_by'] as String?,
      assignedDoctorProfileId: map['assigned_doctor_profile_id'] as String?,
      assignedPhysiotherapistProfileId:
          map['assigned_physiotherapist_profile_id'] as String?,
      assignedDoctorDisplayName: _doctorDisplayNameFromEmbed(map),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      deletedAt: _parseDateTime(map['deleted_at']),
      patientFirstName: embed?.$1,
      patientLastName: embed?.$2,
      patientFileNumber: embed?.$3,
    );
  }

  String? get embeddedPatientFullName {
    final first = patientFirstName?.trim() ?? '';
    final last = patientLastName?.trim() ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? null : full;
  }

  static (String, String, String?)? _parsePatientEmbed(dynamic value) {
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
    final fileNumber = (map['file_number'] as String?)?.trim();
    if (fn.isEmpty && ln.isEmpty) return null;
    return (fn, ln, fileNumber?.isEmpty == true ? null : fileNumber);
  }

  static String? _doctorDisplayNameFromEmbed(Map<String, dynamic> map) {
    final embed = map['assigned_doctor'];
    if (embed is Map) {
      final name = embed['display_name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  static String? _nullableTrimmed(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime _requireAppointmentAt(dynamic value) {
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
