import '../models/appointment.dart';
import 'appointment_remote_display.dart';

/// Randevu detay — remote fallback alan görünürlüğü.
abstract final class AppointmentDetailDisplay {
  static bool showReasonSection(Appointment appointment) {
    return AppointmentRemoteDisplay.showReasonSection(appointment);
  }

  static bool showDuration(Appointment appointment, {required bool usesRemote}) {
    return AppointmentRemoteDisplay.showDuration(
      appointment,
      usesRemote: usesRemote,
    );
  }

  static bool showControlDate(Appointment appointment) {
    return AppointmentRemoteDisplay.showControlDate(appointment);
  }

  static bool showNotesSection(Appointment appointment) {
    return AppointmentRemoteDisplay.showNotesSection(appointment);
  }

  static bool showPatientFileNumber(String? fileNumber) {
    return AppointmentRemoteDisplay.showPatientFileNumber(fileNumber);
  }
}
