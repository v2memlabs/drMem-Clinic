import '../models/appointment.dart';
import 'appointment_remote_display.dart';

/// Randevu listesi kartı — meta satırı (remote fallback uyumlu).
abstract final class AppointmentListDisplay {
  static String? cardMetaLine(Appointment appointment, {required bool usesRemote}) {
    return AppointmentRemoteDisplay.cardMetaLine(
      appointment,
      usesRemote: usesRemote,
    );
  }
}
