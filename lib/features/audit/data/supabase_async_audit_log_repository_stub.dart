import '../models/audit_log.dart';
import 'async_audit_log_repository_contract.dart';
import 'audit_log_repository_failure.dart';

class SupabaseAsyncAuditLogRepositoryStub
    implements AsyncAuditLogRepositoryContract {
  const SupabaseAsyncAuditLogRepositoryStub();

  Never _notConfigured() => throw const AuditLogRepositoryException(
        AuditLogRepositoryFailure.notConfigured,
      );

  @override
  Future<List<AuditLog>> getAll() async => _notConfigured();

  @override
  Future<List<AuditLog>> getByPatientId(String patientId) async =>
      _notConfigured();

  @override
  Future<AuditLog?> getById(String id) async => _notConfigured();

  @override
  Future<List<AuditLog>> getFiltered({
    String? patientId,
    String? query,
    ActionType? actionTypeFilter,
    ModuleType? moduleFilter,
  }) async =>
      _notConfigured();
}
