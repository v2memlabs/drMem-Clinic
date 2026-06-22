/// Timeline RPC `event_type` — dot-notation (bilinmeyen → [other]).
enum TimelineEventType {
  patientCreated('patient.created'),
  patientUpdated('patient.updated'),
  appointmentCreated('appointment.created'),
  appointmentUpdated('appointment.updated'),
  appointmentCancelled('appointment.cancelled'),
  appointmentCompleted('appointment.completed'),
  clinicalEncounterCreated('clinical.encounter.created'),
  clinicalEncounterUpdated('clinical.encounter.updated'),
  clinicalEncounterCompleted('clinical.encounter.completed'),
  fileMetadataCreated('file.metadata.created'),
  fileMetadataArchived('file.metadata.archived'),
  pdfMetadataCreated('pdf.metadata.created'),
  pdfMetadataArchived('pdf.metadata.archived'),
  other('other');

  const TimelineEventType(this.dbValue);

  final String dbValue;

  static TimelineEventType fromDbValue(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return TimelineEventType.other;
    for (final value in TimelineEventType.values) {
      if (value.dbValue == s) return value;
    }
    return TimelineEventType.other;
  }
}

/// Timeline RPC `event_group`.
enum TimelineEventGroup {
  patient('patient'),
  appointment('appointment'),
  clinical('clinical'),
  file('file'),
  pdf('pdf'),
  consent('consent'),
  physiotherapy('physiotherapy'),
  other('other');

  const TimelineEventGroup(this.dbValue);

  final String dbValue;

  static TimelineEventGroup fromDbValue(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return TimelineEventGroup.other;
    for (final value in TimelineEventGroup.values) {
      if (value.dbValue == s) return value;
    }
    return TimelineEventGroup.other;
  }
}

/// Timeline RPC `visibility_scope`.
enum TimelineVisibilityScope {
  doctorAdmin('doctor_admin'),
  clinicOperations('clinic_operations'),
  physiotherapy('physiotherapy'),
  patientShareLater('patient_share_later'),
  other('other');

  const TimelineVisibilityScope(this.dbValue);

  final String dbValue;

  static TimelineVisibilityScope fromDbValue(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return TimelineVisibilityScope.other;
    for (final value in TimelineVisibilityScope.values) {
      if (value.dbValue == s) return value;
    }
    return TimelineVisibilityScope.other;
  }
}
