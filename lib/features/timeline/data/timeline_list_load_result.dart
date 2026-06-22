import '../models/timeline_event.dart';
import 'timeline_list_failure_presentation.dart';

/// Hasta timeline listesi yükleme sonucu.
class TimelineListLoadResult {
  final List<TimelineEvent> events;
  final bool isNotConfigured;
  final bool requiresPatientContext;
  final bool isSessionRequired;
  final TimelineListFailurePresentation? errorPresentation;

  const TimelineListLoadResult._({
    required this.events,
    this.isNotConfigured = false,
    this.requiresPatientContext = false,
    this.isSessionRequired = false,
    this.errorPresentation,
  });

  factory TimelineListLoadResult.success(List<TimelineEvent> events) {
    return TimelineListLoadResult._(events: events);
  }

  factory TimelineListLoadResult.notConfigured() {
    return const TimelineListLoadResult._(
      events: [],
      isNotConfigured: true,
    );
  }

  factory TimelineListLoadResult.sessionRequired() {
    return const TimelineListLoadResult._(
      events: [],
      isSessionRequired: true,
    );
  }

  factory TimelineListLoadResult.requiresPatient() {
    return const TimelineListLoadResult._(
      events: [],
      requiresPatientContext: true,
    );
  }

  factory TimelineListLoadResult.failure(
    TimelineListFailurePresentation presentation,
  ) {
    return TimelineListLoadResult._(
      events: const [],
      errorPresentation: presentation,
    );
  }

  bool get hasError => errorPresentation != null;

  String? get errorTitle => errorPresentation?.title;

  String? get errorDescription => errorPresentation?.description;

  bool get showRetry => errorPresentation?.showRetry ?? false;
}
