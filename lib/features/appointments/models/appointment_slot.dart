/// Randevu formu — tek saat bloğu.
class AppointmentSlot {
  final DateTime start;
  final DateTime end;
  final bool isAvailable;
  final bool isSelected;
  final bool isCurrentAppointmentSlot;
  final String? disabledReason;
  final String label;

  const AppointmentSlot({
    required this.start,
    required this.end,
    required this.isAvailable,
    this.isSelected = false,
    this.isCurrentAppointmentSlot = false,
    this.disabledReason,
    required this.label,
  });

  AppointmentSlot copyWith({
    bool? isSelected,
  }) {
    return AppointmentSlot(
      start: start,
      end: end,
      isAvailable: isAvailable,
      isSelected: isSelected ?? this.isSelected,
      isCurrentAppointmentSlot: isCurrentAppointmentSlot,
      disabledReason: disabledReason,
      label: label,
    );
  }
}

/// Gün bazlı slot üretim sonucu.
enum AppointmentDayAvailabilityReason {
  none,
  workingDayClosed,
  closedDate,
  noAvailableSlots,
}

class AppointmentAvailabilityResult {
  final List<AppointmentSlot> slots;
  final AppointmentDayAvailabilityReason reason;
  final String? message;

  const AppointmentAvailabilityResult({
    required this.slots,
    this.reason = AppointmentDayAvailabilityReason.none,
    this.message,
  });

  bool get hasSelectableSlot =>
      slots.any((s) => s.isAvailable || s.isCurrentAppointmentSlot);
}
