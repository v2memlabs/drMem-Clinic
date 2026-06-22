import '../models/timeline_event.dart';
import '../models/timeline_event_enums.dart';
import 'timeline_event_dto.dart';
import 'timeline_metadata_sanitizer.dart';
import 'timeline_repository_failure.dart';

/// [TimelineEventDto] → [TimelineEvent].
abstract final class TimelineEventMapper {
  static const String defaultTitle = 'Klinik olay';

  static TimelineEvent fromDto(TimelineEventDto dto) {
    final trimmedTitle = dto.title.trim();
    final title = trimmedTitle.isEmpty ? defaultTitle : trimmedTitle;

    return TimelineEvent(
      eventId: dto.eventId.trim(),
      tenantId: dto.tenantId.trim(),
      patientId: dto.patientId.trim(),
      eventType: TimelineEventType.fromDbValue(dto.eventType),
      eventGroup: TimelineEventGroup.fromDbValue(dto.eventGroup),
      title: title,
      subtitle: _trimOptional(dto.subtitle),
      occurredAt: dto.occurredAt,
      sourceEntityType: dto.sourceEntityType.trim(),
      sourceEntityId: _trimOptional(dto.sourceEntityId),
      actorDisplayName: _trimOptional(dto.actorDisplayName),
      visibilityScope: TimelineVisibilityScope.fromDbValue(dto.visibilityScope),
      iconKey: _trimOptional(dto.iconKey),
      status: _trimOptional(dto.status),
      metadata: Map<String, Object?>.unmodifiable(
        TimelineMetadataSanitizer.sanitize(dto.metadata),
      ),
    );
  }

  static TimelineEvent fromMap(Map<String, dynamic> map) {
    return fromDto(TimelineEventDto.fromMap(map));
  }

  static TimelineEvent fromRpcRow(Map<String, dynamic> map) {
    return fromDto(TimelineEventDto.fromRpcRow(map));
  }

  static String? _trimOptional(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}
