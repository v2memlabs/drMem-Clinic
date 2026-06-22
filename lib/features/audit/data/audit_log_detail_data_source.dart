import '../../../core/data/repository_registry.dart';
import '../models/audit_log.dart';
import 'audit_log_repository_failure.dart';
import 'audit_log_user_messages.dart';

class AuditLogDetailLoadResult {
  final AuditLog? log;
  final String? errorMessage;
  final bool notConfigured;

  const AuditLogDetailLoadResult._({
    this.log,
    this.errorMessage,
    this.notConfigured = false,
  });

  factory AuditLogDetailLoadResult.success(AuditLog log) {
    return AuditLogDetailLoadResult._(log: log);
  }

  factory AuditLogDetailLoadResult.failure(String message) {
    return AuditLogDetailLoadResult._(errorMessage: message);
  }

  factory AuditLogDetailLoadResult.notConfigured() {
    return const AuditLogDetailLoadResult._(notConfigured: true);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class AuditLogDetailDataSource {
  static Future<AuditLogDetailLoadResult> load(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return AuditLogDetailLoadResult.failure(AuditLogUserMessages.notFound);
    }

    try {
      final log = await RepositoryRegistry.auditLogsAsync.getById(trimmed);
      if (log == null) {
        return AuditLogDetailLoadResult.failure(AuditLogUserMessages.notFound);
      }
      return AuditLogDetailLoadResult.success(log);
    } on AuditLogRepositoryException catch (e) {
      if (e.reason == AuditLogRepositoryFailure.notConfigured ||
          e.reason == AuditLogRepositoryFailure.noActiveTenant) {
        return AuditLogDetailLoadResult.notConfigured();
      }
      return AuditLogDetailLoadResult.failure(
        AuditLogUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return AuditLogDetailLoadResult.failure(
        AuditLogUserMessages.genericLoadFailure,
      );
    }
  }
}
