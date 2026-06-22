import '../models/audit_log.dart';
import 'async_audit_log_repository_contract.dart';
import 'audit_log_repository.dart';

class MockAsyncAuditLogRepositoryAdapter
    implements AsyncAuditLogRepositoryContract {
  AuditLogRepository get _sync => AuditLogRepository.instance;

  @override
  Future<List<AuditLog>> getAll() async => _sync.getAll();

  @override
  Future<List<AuditLog>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<AuditLog?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<AuditLog>> getFiltered({
    String? patientId,
    String? query,
    ActionType? actionTypeFilter,
    ModuleType? moduleFilter,
  }) async =>
      _sync.getFiltered(
        patientId: patientId,
        query: query,
        actionTypeFilter: actionTypeFilter,
        moduleFilter: moduleFilter,
      );
}
