import 'timeline_event_parse_helpers.dart';
import 'timeline_metadata_sanitizer.dart';
import 'timeline_repository_failure.dart';

/// `list_patient_timeline_events` RPC satırı — allowlist kolonlar.
///
/// Audit access event, internal note, clinical_data, storage path yok.
class TimelineEventDto {
  final String eventId;
  final String tenantId;
  final String patientId;
  final String eventType;
  final String eventGroup;
  final String title;
  final String? subtitle;
  final DateTime occurredAt;
  final String sourceEntityType;
  final String? sourceEntityId;
  final String? actorDisplayName;
  final String visibilityScope;
  final String? iconKey;
  final String? status;
  final Map<String, Object?> metadata;

  const TimelineEventDto({
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

  factory TimelineEventDto.fromMap(Map<String, dynamic> map) {
    try {
      return TimelineEventDto.fromRpcRow(map);
    } on TimelineRepositoryException {
      rethrow;
    } catch (_) {
      throw const TimelineRepositoryException(
        TimelineRepositoryFailure.invalidRow,
      );
    }
  }

  factory TimelineEventDto.fromRpcRow(Map<String, dynamic> map) {
    // Top-level forbidden keys intentionally not read into DTO fields.
    // map['internal_doctor_note'], map['clinical_data'], map['storage_path'] ignored.

    final rawMeta = TimelineEventParseHelpers.coerceMetadataMap(map['metadata']);

    return TimelineEventDto(
      eventId: TimelineEventParseHelpers.requireString(map, 'event_id'),
      tenantId: TimelineEventParseHelpers.requireString(map, 'tenant_id'),
      patientId: TimelineEventParseHelpers.requireString(map, 'patient_id'),
      eventType: TimelineEventParseHelpers.requireString(map, 'event_type'),
      eventGroup: TimelineEventParseHelpers.requireString(map, 'event_group'),
      title: TimelineEventParseHelpers.optionalString(map['title']) ?? '',
      subtitle: TimelineEventParseHelpers.optionalString(map['subtitle']),
      occurredAt: TimelineEventParseHelpers.requireDateTime(map['occurred_at']),
      sourceEntityType:
          TimelineEventParseHelpers.requireString(map, 'source_entity_type'),
      sourceEntityId: TimelineEventParseHelpers.optionalString(
        map['source_entity_id'],
      ),
      actorDisplayName: TimelineEventParseHelpers.optionalString(
        map['actor_display_name'],
      ),
      visibilityScope:
          TimelineEventParseHelpers.requireString(map, 'visibility_scope'),
      iconKey: TimelineEventParseHelpers.optionalString(map['icon_key']),
      status: TimelineEventParseHelpers.optionalString(map['status']),
      metadata: TimelineMetadataSanitizer.sanitize(rawMeta),
    );
  }
}
