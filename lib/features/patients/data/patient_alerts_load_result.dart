import '../models/patient_alert.dart';

class PatientAlertsLoadResult {
  final List<PatientAlert> alerts;
  final bool hasError;
  final String? errorMessage;
  final bool isPartialError;

  const PatientAlertsLoadResult({
    this.alerts = const [],
    this.hasError = false,
    this.errorMessage,
    this.isPartialError = false,
  });

  bool get isEmpty => alerts.isEmpty && !hasError;
}
