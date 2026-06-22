import '../models/audit_log.dart';

abstract interface class AsyncAuditLogRepositoryContract {
  Future<List<AuditLog>> getAll();

  Future<List<AuditLog>> getByPatientId(String patientId);

  Future<AuditLog?> getById(String id);

  Future<List<AuditLog>> getFiltered({
    String? patientId,
    String? query,
    ActionType? actionTypeFilter,
    ModuleType? moduleFilter,
  });
}
