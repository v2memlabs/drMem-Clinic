import '../models/timeline_event.dart';
import 'timeline_repository.dart';
import 'timeline_repository_failure.dart';

/// Timeline repository — Supabase RPC henüz bağlı değil.
class TimelineRepositoryStub implements TimelineRepository {
  const TimelineRepositoryStub();

  Future<T> _notConfigured<T>() async {
    throw const TimelineRepositoryException(
      TimelineRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<TimelineEvent>> listPatientTimelineEvents({
    required String patientId,
  }) =>
      _notConfigured();
}

/// @deprecated Use [TimelineRepositoryStub].
typedef SupabaseTimelineRepositoryStub = TimelineRepositoryStub;
