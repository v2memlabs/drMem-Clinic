import '../../../core/data/repository_registry.dart';
import '../models/audit_log.dart';
import 'audit_log_list_load_result.dart';
import 'audit_log_repository_failure.dart';
import 'audit_log_user_messages.dart';

abstract final class AuditLogListDataSource {
  static Future<AuditLogListLoadResult> load({
    String? patientId,
    required String query,
    ActionType? actionTypeFilter,
    ModuleType? moduleFilter,
  }) async {
    try {
      final repo = RepositoryRegistry.auditLogsAsync;
      final list = await repo.getFiltered(
        patientId: patientId,
        query: query,
        actionTypeFilter: actionTypeFilter,
        moduleFilter: moduleFilter,
      );
      return AuditLogListLoadResult.success(list);
    } on AuditLogRepositoryException catch (e) {
      if (e.reason == AuditLogRepositoryFailure.notConfigured ||
          e.reason == AuditLogRepositoryFailure.noActiveTenant) {
        return AuditLogListLoadResult.notConfigured();
      }
      return AuditLogListLoadResult.failure(
        AuditLogUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return AuditLogListLoadResult.failure(
        AuditLogUserMessages.genericLoadFailure,
      );
    }
  }
}
