import 'audit_access_event.dart';
import 'audit_access_event_recorder.dart';

/// Remote hazır değilken sessiz recorder.
final class NoOpAuditAccessEventRecorder implements AuditAccessEventRecorder {
  const NoOpAuditAccessEventRecorder();

  static const NoOpAuditAccessEventRecorder instance =
      NoOpAuditAccessEventRecorder();

  @override
  Future<void> record(AuditAccessEvent event) async {}
}
