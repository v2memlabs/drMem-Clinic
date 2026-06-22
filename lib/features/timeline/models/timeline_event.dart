import 'timeline_event_enums.dart';

/// Hasta timeline olayı — klinik/operasyonel geçmiş (audit log değil).
///
/// Legacy mock UI: `lib/features/patients/models/patient_timeline_event.dart`.
class TimelineEvent {
  final String eventId;
  final String tenantId;
  final String patientId;
  final TimelineEventType eventType;
  final TimelineEventGroup eventGroup;
  final String title;
  final String? subtitle;
  final DateTime occurredAt;
  final String sourceEntityType;
  final String? sourceEntityId;
  final String? actorDisplayName;
  final TimelineVisibilityScope visibilityScope;
  final String? iconKey;
  final String? status;
  final Map<String, Object?> metadata;

  const TimelineEvent({
    required this.eventId,
    required this.tenantId,
    required this.patientId,
    required this.eventType,
    required this.eventGroup,
    required this.title,
    this.subtitle,
    required this.occurredAt,
    required this.sourceEntityType,
    this.sourceEntityId,
    this.actorDisplayName,
    required this.visibilityScope,
    this.iconKey,
    this.status,
    this.metadata = const {},
  });

  /// Orijinal RPC `event_type` (enum [other] ise ham değer korunmaz — dbValue other).
  String get eventTypeValue => eventType.dbValue;

  String get eventGroupValue => eventGroup.dbValue;

  String get visibilityScopeValue => visibilityScope.dbValue;
}
