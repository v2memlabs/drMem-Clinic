import '../models/audit_log.dart';

class AuditLogListLoadResult {
  final List<AuditLog> logs;
  final String? errorMessage;
  final bool notConfigured;

  const AuditLogListLoadResult._({
    this.logs = const [],
    this.errorMessage,
    this.notConfigured = false,
  });

  factory AuditLogListLoadResult.success(List<AuditLog> logs) {
    return AuditLogListLoadResult._(logs: logs);
  }

  factory AuditLogListLoadResult.failure(String message) {
    return AuditLogListLoadResult._(errorMessage: message);
  }

  factory AuditLogListLoadResult.notConfigured() {
    return const AuditLogListLoadResult._(notConfigured: true);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
