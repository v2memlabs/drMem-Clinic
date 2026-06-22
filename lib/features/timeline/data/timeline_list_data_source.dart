import '../../../core/data/repository_registry.dart';
import 'timeline_list_load_result.dart';
import 'timeline_list_user_messages.dart';
import 'timeline_module_availability.dart';
import 'timeline_repository_failure.dart';

/// Hasta timeline — [RepositoryRegistry.patientTimeline].
abstract final class TimelineListDataSource {
  static Future<TimelineListLoadResult> load({
    required String patientId,
  }) async {
    final pid = patientId.trim();
    if (pid.isEmpty) {
      return TimelineListLoadResult.requiresPatient();
    }

    if (!TimelineModuleAvailability.isOperational) {
      return TimelineListLoadResult.notConfigured();
    }

    try {
      final repo = RepositoryRegistry.patientTimeline;
      final list = await repo.listPatientTimelineEvents(patientId: pid);
      list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      return TimelineListLoadResult.success(list);
    } on TimelineRepositoryException catch (e) {
      return _resultForRepositoryFailure(e.reason);
    } catch (_) {
      return TimelineListLoadResult.failure(
        TimelineListUserMessages.genericFailurePresentation(),
      );
    }
  }

  static TimelineListLoadResult _resultForRepositoryFailure(
    TimelineRepositoryFailure reason,
  ) {
    switch (reason) {
      case TimelineRepositoryFailure.notConfigured:
        return TimelineListLoadResult.notConfigured();
      case TimelineRepositoryFailure.noActiveTenant:
        return TimelineListLoadResult.sessionRequired();
      case TimelineRepositoryFailure.notFound:
        return TimelineListLoadResult.success(const []);
      case TimelineRepositoryFailure.forbidden:
      case TimelineRepositoryFailure.network:
      case TimelineRepositoryFailure.invalidRow:
      case TimelineRepositoryFailure.invalidInput:
      case TimelineRepositoryFailure.unknown:
        return TimelineListLoadResult.failure(
          TimelineListUserMessages.presentationForFailure(reason),
        );
    }
  }
}
