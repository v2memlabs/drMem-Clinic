import '../models/patient.dart';

/// Hasta detay yükleme sonucu.
class PatientDetailLoadResult {
  final Patient? patient;
  final String? errorMessage;

  const PatientDetailLoadResult._({
    this.patient,
    this.errorMessage,
  });

  factory PatientDetailLoadResult.success(Patient patient) {
    return PatientDetailLoadResult._(patient: patient);
  }

  factory PatientDetailLoadResult.notFound() {
    return const PatientDetailLoadResult._();
  }

  factory PatientDetailLoadResult.failure(String message) {
    return PatientDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
