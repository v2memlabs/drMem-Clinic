import '../models/appointment.dart';
import 'appointment_remote_mapper.dart';

/// Remote v1 — randevu UI fallback ve görünürlük yardımcıları.
abstract final class AppointmentRemoteDisplay {
  static const String patientNameFallbackLabel = 'Hasta bilgisi';

  static String patientDisplayName(String patientName) {
    final trimmed = patientName.trim();
    if (trimmed.isEmpty ||
        trimmed == AppointmentRemoteMapper.defaultPatientName) {
      return patientNameFallbackLabel;
    }
    return trimmed;
  }

  static bool isDefaultPatientName(String patientName) {
    final trimmed = patientName.trim();
    return trimmed.isEmpty ||
        trimmed == AppointmentRemoteMapper.defaultPatientName;
  }

  static String? cardMetaLine(Appointment appointment, {required bool usesRemote}) {
    final reason = appointment.reason.trim();
    final notes = appointment.notes.trim();

    if (reason.isNotEmpty) {
      return '$reason • ${appointment.durationMinutes} dk';
    }
    if (notes.isNotEmpty) {
      return notes.length > 80 ? '${notes.substring(0, 80)}…' : notes;
    }
    if (!usesRemote) {
      return '${appointment.durationMinutes} dk';
    }
    return null;
  }

  static bool showReasonSection(Appointment appointment) {
    return appointment.reason.trim().isNotEmpty;
  }

  static bool showDuration(Appointment appointment, {required bool usesRemote}) {
    if (!usesRemote) return true;
    return appointment.reason.trim().isNotEmpty;
  }

  static bool showControlDate(Appointment appointment) {
    return appointment.controlDate != null;
  }

  static bool showNotesSection(Appointment appointment) {
    return appointment.notes.trim().isNotEmpty;
  }

  static bool showPatientFileNumber(String? fileNumber) {
    return fileNumber != null && fileNumber.trim().isNotEmpty;
  }
}
