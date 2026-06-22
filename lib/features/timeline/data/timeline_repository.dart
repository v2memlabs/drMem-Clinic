import '../models/timeline_event.dart';

/// Hasta timeline — klinik/operasyonel olay akışı (audit log değil).
abstract interface class TimelineRepository {
  Future<List<TimelineEvent>> listPatientTimelineEvents({
    required String patientId,
  });
}
