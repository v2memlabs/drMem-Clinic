import '../models/patient.dart';
import 'async_patient_repository_contract.dart';

/// Hasta listesi yükleme sonucu.
class PatientListLoadResult {
  final List<Patient> patients;
  final PatientListPageCursor? nextCursor;
  final String? errorMessage;

  const PatientListLoadResult._({
    required this.patients,
    this.nextCursor,
    this.errorMessage,
  });

  factory PatientListLoadResult.success(
    List<Patient> patients, {
    PatientListPageCursor? nextCursor,
  }) {
    return PatientListLoadResult._(
      patients: patients,
      nextCursor: nextCursor,
    );
  }

  factory PatientListLoadResult.failure(String message) {
    return PatientListLoadResult._(
      patients: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;

  bool get hasMore => nextCursor != null;
}
