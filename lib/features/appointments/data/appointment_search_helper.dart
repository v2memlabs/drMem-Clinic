import '../models/appointment.dart';

/// Remote v1 arama — DB'de `reason` yok; MVP client-side filtre.
abstract final class AppointmentSearchHelper {
  static List<Appointment> filter(List<Appointment> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;

    return source.where((a) {
      if (a.patientName.toLowerCase().contains(q)) return true;
      if (a.notes.toLowerCase().contains(q)) return true;
      if (appointmentStatusLabel(a.status).toLowerCase().contains(q)) {
        return true;
      }
      if (appointmentTypeLabel(a.type).toLowerCase().contains(q)) {
        return true;
      }
      return false;
    }).toList();
  }
}
