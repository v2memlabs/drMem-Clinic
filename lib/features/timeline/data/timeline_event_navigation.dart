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
        if (!AuthSession.canViewFiles) return null;
        return '/files/$id';
      case TimelineEventGroup.pdf:
        if (!AuthSession.canViewPdfOutputs) return null;
        return '/pdf-outputs/$id';
      case TimelineEventGroup.consent:
        if (!AuthSession.canViewConsents) return null;
        return '/consents/$id';
      case TimelineEventGroup.physiotherapy:
        if (!AuthSession.canViewPhysiotherapy) return null;
        return _physiotherapyRoute(event, id);
      case TimelineEventGroup.patient:
        if (!AuthSession.canViewPatients) return null;
        return '/patients/$id';
      case TimelineEventGroup.other:
        return null;
    }
  }

  static bool canNavigate(TimelineEvent event) {
    final route = routeFor(event);
    return route != null && route.isNotEmpty;
  }

  static String? _physiotherapyRoute(TimelineEvent event, String id) {
    final sourceType = event.sourceEntityType.toLowerCase();
    if (sourceType.contains('session')) {
      return '/physiotherapy/sessions/$id';
    }
    return '/physiotherapy/referrals/$id';
  }

  static bool _isClinicalEvent(TimelineEventType type) {
    return type == TimelineEventType.clinicalEncounterCreated ||
        type == TimelineEventType.clinicalEncounterUpdated ||
        type == TimelineEventType.clinicalEncounterCompleted;
  }
}
