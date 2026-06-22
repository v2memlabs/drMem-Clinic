import 'audit_access_event.dart';
import 'audit_access_event_recorder.dart';
import 'audit_access_legacy_display_mapper.dart';

/// Mock backend — bellek içi kayıt + doktor audit UI için legacy satır.
final class MockAuditAccessEventRecorder implements AuditAccessEventRecorder {
  MockAuditAccessEventRecorder._();

  static final MockAuditAccessEventRecorder instance =
      MockAuditAccessEventRecorder._();

  final List<AuditAccessEvent> events = [];

  @override
  Future<void> record(AuditAccessEvent event) async {
    events.insert(0, event);
    AuditAccessLegacyDisplayMapper.appendLegacyMockLog(event);
  }

  void clear() {
    events.clear();
  }
}
