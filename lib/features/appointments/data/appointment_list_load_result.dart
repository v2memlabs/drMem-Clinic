import '../models/appointment.dart';

/// Randevu listesi yükleme sonucu.
class AppointmentListLoadResult {
  final List<Appointment> appointments;
  final String? errorMessage;

  const AppointmentListLoadResult._({
    required this.appointments,
    this.errorMessage,
  });

  factory AppointmentListLoadResult.success(List<Appointment> appointments) {
    return AppointmentListLoadResult._(appointments: appointments);
  }

  factory AppointmentListLoadResult.failure(String message) {
    return AppointmentListLoadResult._(
      appointments: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
