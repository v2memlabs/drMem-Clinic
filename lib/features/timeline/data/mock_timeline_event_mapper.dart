import '../../patients/data/patient_timeline_builder.dart';
import '../../patients/models/patient_timeline_event.dart' as legacy;
import '../models/timeline_event.dart';
import '../models/timeline_event_enums.dart';

/// Legacy [legacy.PatientTimelineEvent] → [TimelineEvent] (mock backend).
abstract final class MockTimelineEventMapper {
  static const String mockTenantId = 'mock-tenant';

  static TimelineEvent fromLegacy(legacy.PatientTimelineEvent event) {
    return TimelineEvent(
      eventId: event.id,
      tenantId: mockTenantId,
      patientId: event.patientId,
      eventType: _mapEventType(event.eventType),
      eventGroup: _mapEventGroup(event.eventType),
      title: event.title,
      subtitle: event.description.trim().isEmpty ? null : event.description,
      occurredAt: event.eventDate,
      sourceEntityType: event.relatedModule,
      sourceEntityId: null,
      actorDisplayName:
          event.createdBy.trim().isEmpty ? null : event.createdBy.trim(),
      visibilityScope: TimelineVisibilityScope.doctorAdmin,
      metadata: const {},
    );
  }

  static TimelineEventType _mapEventType(legacy.TimelineEventType type) {
    return switch (type) {
      legacy.TimelineEventType.randevu => TimelineEventType.appointmentCreated,
      legacy.TimelineEventType.muayeneNotu =>
        TimelineEventType.clinicalEncounterCreated,
      legacy.TimelineEventType.goruntuleme =>
        TimelineEventType.clinicalEncounterUpdated,
      legacy.TimelineEventType.ameliyatGirisim =>
        TimelineEventType.clinicalEncounterCompleted,
      legacy.TimelineEventType.postOpProtokol =>
        TimelineEventType.clinicalEncounterUpdated,
      legacy.TimelineEventType.fizyoterapiYonlendirme ||
      legacy.TimelineEventType.fizyoterapiSeansi =>
        TimelineEventType.other,
      legacy.TimelineEventType.egzersizProgrami =>
        TimelineEventType.clinicalEncounterUpdated,
      legacy.TimelineEventType.dosya => TimelineEventType.fileMetadataCreated,
      legacy.TimelineEventType.kvkkOnam => TimelineEventType.other,
      legacy.TimelineEventType.odeme => TimelineEventType.other,
      legacy.TimelineEventType.mesaj => TimelineEventType.other,
      legacy.TimelineEventType.pdfCikti => TimelineEventType.pdfMetadataCreated,
      legacy.TimelineEventType.auditLog => TimelineEventType.other,
      legacy.TimelineEventType.anamnez ||
      legacy.TimelineEventType.tani ||
      legacy.TimelineEventType.tedaviPlani =>
        TimelineEventType.clinicalEncounterUpdated,
    };
  }

  static TimelineEventGroup _mapEventGroup(legacy.TimelineEventType type) {
    return switch (type) {
      legacy.TimelineEventType.randevu => TimelineEventGroup.appointment,
      legacy.TimelineEventType.muayeneNotu ||
      legacy.TimelineEventType.goruntuleme ||
      legacy.TimelineEventType.ameliyatGirisim ||
      legacy.TimelineEventType.postOpProtokol ||
      legacy.TimelineEventType.anamnez ||
      legacy.TimelineEventType.tani ||
      legacy.TimelineEventType.tedaviPlani ||
      legacy.TimelineEventType.egzersizProgrami =>
        TimelineEventGroup.clinical,
      legacy.TimelineEventType.dosya => TimelineEventGroup.file,
      legacy.TimelineEventType.pdfCikti => TimelineEventGroup.pdf,
      legacy.TimelineEventType.kvkkOnam => TimelineEventGroup.consent,
      legacy.TimelineEventType.fizyoterapiYonlendirme ||
      legacy.TimelineEventType.fizyoterapiSeansi =>
        TimelineEventGroup.physiotherapy,
      _ => TimelineEventGroup.other,
    };
  }
}
