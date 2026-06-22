import '../../core/auth/auth_session.dart';

/// Bağlamsal PDF oluşturma — route ve görünürlük (UI-only).
abstract final class ContextualPdfActions {
  static const String createLabel = 'PDF Oluştur';

  static bool canShowCreateAction({String? patientId}) {
    if (!AuthSession.canEditPdfOutputs) return false;
    final pid = patientId?.trim();
    return pid != null && pid.isNotEmpty;
  }

  static String newFromPatient(String patientId) {
    return Uri(
      path: '/pdf-outputs/new',
      queryParameters: {'patientId': patientId.trim()},
    ).toString();
  }

  static String newFromClinicalEncounter({
    required String patientId,
    required String clinicalEncounterId,
  }) {
    return Uri(
      path: '/pdf-outputs/new',
      queryParameters: {
        'patientId': patientId.trim(),
        'source': 'clinical_encounter',
        'id': clinicalEncounterId.trim(),
      },
    ).toString();
  }

  static String newFromAppointment({
    required String patientId,
    required String appointmentId,
  }) {
    return Uri(
      path: '/pdf-outputs/new',
      queryParameters: {
        'patientId': patientId.trim(),
        'source': 'appointment',
        'id': appointmentId.trim(),
      },
    ).toString();
  }
}
