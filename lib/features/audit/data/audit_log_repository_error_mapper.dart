import 'audit_log_repository_failure.dart';

abstract final class AuditLogRepositoryErrorMapper {
  static AuditLogRepositoryException toException(Object error) {
    if (error is AuditLogRepositoryException) return error;

    final message = error.toString().toLowerCase();
    if (message.contains('42501') ||
        message.contains('permission denied') ||
        message.contains('not authorized')) {
      return AuditLogRepositoryException(
        AuditLogRepositoryFailure.forbidden,
        cause: error,
      );
    }
    if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('timeout')) {
      return AuditLogRepositoryException(
        AuditLogRepositoryFailure.network,
        cause: error,
      );
    }

    return AuditLogRepositoryException(
      AuditLogRepositoryFailure.unknown,
      cause: error,
    );
  }
}
