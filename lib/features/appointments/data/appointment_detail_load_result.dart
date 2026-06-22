import '../models/appointment.dart';

/// Randevu detay yükleme sonucu.
class AppointmentDetailLoadResult {
  final Appointment? appointment;
  final String? patientFileNumber;
  final String? errorMessage;

  const AppointmentDetailLoadResult._({
    this.appointment,
    this.patientFileNumber,
    this.errorMessage,
  });

  factory AppointmentDetailLoadResult.success({
    required Appointment appointment,
    String? patientFileNumber,
  }) {
    return AppointmentDetailLoadResult._(
      appointment: appointment,
      patientFileNumber: patientFileNumber,
    );
  }

  factory AppointmentDetailLoadResult.notFound() {
    return const AppointmentDetailLoadResult._();
  }

  factory AppointmentDetailLoadResult.failure(String message) {
    return AppointmentDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
