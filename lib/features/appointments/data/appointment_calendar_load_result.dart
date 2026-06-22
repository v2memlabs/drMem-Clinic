import '../models/appointment.dart';

/// Takvim görünümü yükleme sonucu — seçili gün + hafta yoğunlukları.
class AppointmentCalendarLoadResult {
  final List<Appointment> appointments;
  final Map<DateTime, int> weekCounts;
  final String? errorMessage;

  const AppointmentCalendarLoadResult._({
    required this.appointments,
    required this.weekCounts,
    this.errorMessage,
  });

  factory AppointmentCalendarLoadResult.success({
    required List<Appointment> appointments,
    required Map<DateTime, int> weekCounts,
  }) {
    return AppointmentCalendarLoadResult._(
      appointments: appointments,
      weekCounts: weekCounts,
    );
  }

  factory AppointmentCalendarLoadResult.failure(String message) {
    return AppointmentCalendarLoadResult._(
      appointments: const [],
      weekCounts: const {},
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
