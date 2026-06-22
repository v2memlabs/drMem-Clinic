import 'audit_access_event_type.dart';

/// `audit_logs.module` kolonu için üst kategori.
abstract final class AuditAccessEventScope {
  static const String clinical = 'clinical';
  static const String clinicalSummary = 'clinical_summary';
  static const String patient = 'patient';
  static const String appointment = 'appointment';
  static const String file = 'file';
  static const String pdf = 'pdf';
  static const String consent = 'consent';
  static const String security = 'security';
  static const String auth = 'auth';

  static String forEventType(String eventType) {
    if (eventType.startsWith('clinical.summary.')) {
      return clinicalSummary;
    }
    if (eventType.startsWith('clinical.')) return clinical;
    if (eventType.startsWith('patient.')) return patient;
    if (eventType.startsWith('appointment.')) return appointment;
    if (eventType.startsWith('pdf.')) return pdf;
    if (eventType.startsWith('patient_file.') || eventType.startsWith('patient_file.')) {
      return file;
    }
    if (eventType.startsWith('consent.') || eventType.startsWith('kvkk.')) {
      return consent;
    }
    if (eventType.startsWith('auth.') ||
        eventType.startsWith('tenant.') ||
        eventType.startsWith('membership.') ||
        eventType == AuditAccessEventType.permissionDenied) {
      return security;
    }
    return clinical;
  }
}
