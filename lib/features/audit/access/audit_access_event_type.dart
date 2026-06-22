/// KVKK / erişim audit olay tipleri (dot-notation).
///
/// Tam taxonomy: [docs/audit_kvkk_access_event_extension_v1.md](../../../docs/audit_kvkk_access_event_extension_v1.md)
abstract final class AuditAccessEventType {
  // Clinical full (doctor/admin)
  static const String clinicalFullList = 'clinical.full.list';
  static const String clinicalFullView = 'clinical.full.view';
  static const String clinicalFullCreate = 'clinical.full.create';
  static const String clinicalFullUpdate = 'clinical.full.update';
  static const String clinicalInternalNoteView = 'clinical.internal_note.view';
  static const String clinicalInternalNoteUpdate = 'clinical.internal_note.update';

  // Safe summary — assistant
  static const String clinicalSummaryAssistantList =
      'clinical.summary.assistant.list';
  static const String clinicalSummaryAssistantView =
      'clinical.summary.assistant.view';

  // Safe summary — physiotherapist
  static const String clinicalSummaryPhysiotherapistList =
      'clinical.summary.physiotherapist.list';
  static const String clinicalSummaryPhysiotherapistView =
      'clinical.summary.physiotherapist.view';

  // Security
  static const String permissionDenied = 'permission.denied';

  // Patient (taxonomy — sonraki paket)
  static const String patientView = 'patient.view';
  static const String patientList = 'patient.list';

  // Appointment (taxonomy — sonraki paket)
  static const String appointmentView = 'appointment.view';
  static const String appointmentList = 'appointment.list';
}
