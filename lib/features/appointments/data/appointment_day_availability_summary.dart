import '../models/appointment_slot.dart';

/// Gün özeti — müsait slot metni (liste üst bandı).
abstract final class AppointmentDayAvailabilitySummary {
  static String? slotStatsLabel(AppointmentAvailabilityResult? availability) {
    if (availability == null) return null;

    final reason = availability.reason;
    if (reason == AppointmentDayAvailabilityReason.workingDayClosed ||
        reason == AppointmentDayAvailabilityReason.closedDate) {
      final message = availability.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return 'Kapalı gün';
    }

    if (reason == AppointmentDayAvailabilityReason.noAvailableSlots) {
      return 'Müsait slot yok';
    }

    final free = availability.slots.where((s) => s.isAvailable).length;
    return '$free boş slot';
  }
}
