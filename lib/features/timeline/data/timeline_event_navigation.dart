import '../../../core/auth/auth_session.dart';
import '../models/timeline_event.dart';
import '../models/timeline_event_enums.dart';

/// Timeline olayına güvenli gezinme — teknik ID UI'da gösterilmez.
abstract final class TimelineEventNavigation {
  static String? routeFor(TimelineEvent event) {
    final id = event.sourceEntityId?.trim();
    if (id == null || id.isEmpty) return null;

    switch (event.eventGroup) {
      case TimelineEventGroup.clinical:
        if (!AuthSession.canViewClinicalEncounters) return null;
        if (!_isClinicalEvent(event.eventType)) return null;
        return '/clinical-records/$id';
      case TimelineEventGroup.appointment:
        if (!AuthSession.canViewAppointments) return null;
        return '/appointments/$id';
      case TimelineEventGroup.file:
      case TimelineEventGroup.pdf:
      case TimelineEventGroup.patient:
      case TimelineEventGroup.consent:
      case TimelineEventGroup.physiotherapy:
      case TimelineEventGroup.other:
        return null;
    }
  }

  static bool _isClinicalEvent(TimelineEventType type) {
    return type == TimelineEventType.clinicalEncounterCreated ||
        type == TimelineEventType.clinicalEncounterUpdated ||
        type == TimelineEventType.clinicalEncounterCompleted;
  }
}
