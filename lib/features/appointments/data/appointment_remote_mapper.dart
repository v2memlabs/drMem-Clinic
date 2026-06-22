import '../models/appointment.dart';
import 'appointment_datetime_helper.dart';
import 'appointment_remote_row.dart';
import 'appointment_status_mapping.dart';
import 'appointment_type_mapping.dart';

/// Supabase `appointments` satırı ↔ [Appointment] (query yok).
abstract final class AppointmentRemoteMapper {
  static const int defaultDurationMinutes = 30;
  static const String defaultPatientName = 'Hasta';

  static Appointment fromRow(Map<String, dynamic> row) {
    return fromRemoteRow(AppointmentRemoteRow.fromMap(row));
  }

  static Appointment fromRemoteRow(AppointmentRemoteRow row) {
    final atLocal =
        AppointmentDateTimeHelper.toLocalForDisplay(row.appointmentAt);
    final patientName = row.embeddedPatientFullName ?? defaultPatientName;

    return Appointment(
      id: row.id ?? '',
      patientId: row.patientId,
      patientName: patientName,
      patientFileNumber: row.patientFileNumber,
      appointmentDateTime: atLocal,
      durationMinutes: defaultDurationMinutes,
      type: AppointmentTypeMapping.fromDb(row.appointmentType),
      status: AppointmentStatusMapping.fromDb(row.status),
      reason: '',
      controlDate: null,
      notes: row.notes ?? '',
      assignedDoctorProfileId: row.assignedDoctorProfileId,
      assignedDoctorName: row.assignedDoctorDisplayName,
      assignedPhysiotherapistProfileId: row.assignedPhysiotherapistProfileId,
      createdByProfileId: row.createdBy,
    );
  }

  /// Insert — `id` / timestamp / `deleted_at` gönderilmez; `tenant_id` scope'tan.
  static Map<String, dynamic> toInsertRow(
    Appointment appointment, {
    required String tenantId,
    String? createdByProfileId,
  }) {
    return {
      'tenant_id': tenantId,
      'patient_id': appointment.patientId,
      'appointment_at': AppointmentDateTimeHelper.toUtcIsoString(
        appointment.appointmentDateTime,
      ),
      'status': AppointmentStatusMapping.toDb(appointment.status),
      'appointment_type': AppointmentTypeMapping.toDb(appointment.type),
      'notes': _notesToDb(appointment.notes),
      if (createdByProfileId != null && createdByProfileId.trim().isNotEmpty)
        'created_by': createdByProfileId.trim(),
      if (appointment.assignedDoctorProfileId != null &&
          appointment.assignedDoctorProfileId!.trim().isNotEmpty)
        'assigned_doctor_profile_id':
            appointment.assignedDoctorProfileId!.trim(),
      if (appointment.assignedPhysiotherapistProfileId != null &&
          appointment.assignedPhysiotherapistProfileId!.trim().isNotEmpty)
        'assigned_physiotherapist_profile_id':
            appointment.assignedPhysiotherapistProfileId!.trim(),
    };
  }

  /// Update — `id`, `tenant_id`, `patient_id`, `deleted_at` yok.
  static Map<String, dynamic> toUpdateRow(Appointment appointment) {
    return {
      'appointment_at': AppointmentDateTimeHelper.toUtcIsoString(
        appointment.appointmentDateTime,
      ),
      'status': AppointmentStatusMapping.toDb(appointment.status),
      'appointment_type': AppointmentTypeMapping.toDb(appointment.type),
      'notes': _notesToDb(appointment.notes),
      if (appointment.assignedDoctorProfileId != null &&
          appointment.assignedDoctorProfileId!.trim().isNotEmpty)
        'assigned_doctor_profile_id':
            appointment.assignedDoctorProfileId!.trim(),
      if (appointment.assignedPhysiotherapistProfileId != null &&
          appointment.assignedPhysiotherapistProfileId!.trim().isNotEmpty)
        'assigned_physiotherapist_profile_id':
            appointment.assignedPhysiotherapistProfileId!.trim(),
    };
  }

  /// İptal — kayıt listede kalır.
  static Map<String, dynamic> toCancelRow() {
    return {'status': AppointmentStatusMapping.cancelled};
  }

  /// Arşiv — listeden düşer; mevcut `status` korunur (yalnız `deleted_at` set).
  static Map<String, dynamic> toArchiveRow({DateTime? at}) {
    final when = (at ?? DateTime.now()).toUtc();
    return {'deleted_at': when.toIso8601String()};
  }

  static String? _notesToDb(String notes) {
    final t = notes.trim();
    return t.isEmpty ? null : t;
  }
}
