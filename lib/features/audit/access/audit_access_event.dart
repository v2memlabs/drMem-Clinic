import 'audit_access_event_scope.dart';

/// Append-only erişim audit kaydı (hassas içerik taşımaz).
class AuditAccessEvent {
  final String eventType;
  final String eventScope;
  final bool success;
  final String? failureCategory;
  final String source;
  final String? patientId;
  final String? encounterId;
  final String? appointmentId;
  final String? fileId;
  final Map<String, Object?> metadata;

  AuditAccessEvent({
    required this.eventType,
    String? eventScope,
    this.success = true,
    this.failureCategory,
    this.source = 'repository',
    this.patientId,
    this.encounterId,
    this.appointmentId,
    this.fileId,
    Map<String, Object?>? metadata,
  })  : eventScope = eventScope ?? AuditAccessEventScope.forEventType(eventType),
        metadata = metadata ?? const {};

  String? get recordId => encounterId ?? appointmentId ?? fileId;
}
