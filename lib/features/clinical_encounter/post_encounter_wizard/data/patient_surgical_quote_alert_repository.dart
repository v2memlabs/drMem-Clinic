import '../models/patient_surgical_quote_alert.dart';
import 'mock_patient_surgical_quote_alerts.dart';

class PatientSurgicalQuoteAlertRepository {
  PatientSurgicalQuoteAlertRepository._();

  static final PatientSurgicalQuoteAlertRepository instance =
      PatientSurgicalQuoteAlertRepository._();

  PatientSurgicalQuoteAlert? activeForPatient(String patientId) {
    final pid = patientId.trim();
    if (pid.isEmpty) return null;

    PatientSurgicalQuoteAlert? latest;
    for (final alert in mockPatientSurgicalQuoteAlerts) {
      if (alert.patientId != pid || alert.isDismissed) continue;
      if (latest == null || alert.createdAt.isAfter(latest.createdAt)) {
        latest = alert;
      }
    }
    return latest;
  }

  void add(PatientSurgicalQuoteAlert alert) {
    mockPatientSurgicalQuoteAlerts.insert(0, alert);
  }

  void dismiss(String alertId, {required String dismissedBy, required DateTime at}) {
    final index =
        mockPatientSurgicalQuoteAlerts.indexWhere((a) => a.id == alertId);
    if (index < 0) return;
    mockPatientSurgicalQuoteAlerts[index] =
        mockPatientSurgicalQuoteAlerts[index].dismiss(
      at: at,
      dismissedBy: dismissedBy,
    );
  }
}
