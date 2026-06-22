import '../../patients/data/patient_timeline_builder.dart';
import '../../patients/models/patient_timeline_event.dart' as legacy;
import '../models/timeline_event.dart';
import 'mock_timeline_event_mapper.dart';
import 'timeline_repository.dart';

/// Mock hasta timeline — [PatientTimelineBuilder] (audit log hariç).
class MockTimelineRepository implements TimelineRepository {
  @override
  Future<List<TimelineEvent>> listPatientTimelineEvents({
    required String patientId,
  }) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    final legacyEvents = (await PatientTimelineBuilder.buildAsync(patientId: pid))
        .where((e) => e.eventType != legacy.TimelineEventType.auditLog)
        .map(MockTimelineEventMapper.fromLegacy)
        .toList();

    return List<TimelineEvent>.from(legacyEvents);
  }
}
