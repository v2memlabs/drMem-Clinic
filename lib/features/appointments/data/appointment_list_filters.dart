import '../models/appointment.dart';

/// Randevu listesi — client-side filtre (period/status).
abstract final class AppointmentListFilters {
  static List<Appointment> applyPeriod(List<Appointment> list, String period) {
    if (period == 'all') return list;

    final now = DateTime.now();
    if (period == 'today') {
      return list
          .where(
            (a) =>
                a.appointmentDateTime.year == now.year &&
                a.appointmentDateTime.month == now.month &&
                a.appointmentDateTime.day == now.day,
          )
          .toList();
    }

    if (period == 'week') {
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return list
          .where(
            (a) =>
                !a.appointmentDateTime.isBefore(start) &&
                !a.appointmentDateTime.isAfter(end),
          )
          .toList();
    }

    return list;
  }

  static List<Appointment> applyStatus(
    List<Appointment> list,
    AppointmentStatus? status,
  ) {
    if (status == null) return list;
    return list.where((a) => a.status == status).toList();
  }
}
