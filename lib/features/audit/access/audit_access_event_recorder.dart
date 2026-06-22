import 'audit_access_event.dart';

/// Erişim audit kaydı — append-only.
abstract interface class AuditAccessEventRecorder {
  Future<void> record(AuditAccessEvent event);
}
