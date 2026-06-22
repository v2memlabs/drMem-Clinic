import '../models/audit_log.dart';
import 'mock_audit_logs.dart';

class AuditLogRepository {
  AuditLogRepository._();

  static final AuditLogRepository instance = AuditLogRepository._();

  List<AuditLog> getAll() => List.unmodifiable(mockAuditLogs);

  AuditLog? getById(String id) {
    for (final record in mockAuditLogs) {
      if (record.id == id) return record;
    }
    return null;
  }

  List<AuditLog> getByPatientId(String patientId) =>
      mockAuditLogs.where((a) => a.patientId == patientId).toList();

  List<AuditLog> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockAuditLogs.where((a) => _matchesQuery(a, q)).toList();
  }

  List<AuditLog> getFiltered({
    String? patientId,
    String? query,
    ActionType? actionTypeFilter,
    ModuleType? moduleFilter,
    String? userFilter,
  }) {
    Iterable<AuditLog> list = mockAuditLogs;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((a) => a.patientId == patientId);
    }
    if (actionTypeFilter != null) {
      list = list.where((a) => a.actionType == actionTypeFilter);
    }
    if (moduleFilter != null) {
      list = list.where((a) => a.module == moduleFilter);
    }
    if (userFilter != null && userFilter.isNotEmpty) {
      final uf = userFilter.toLowerCase();
      list = list.where((a) => a.userName.toLowerCase().contains(uf));
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((a) => matchesQuery(a, q));
    }

    return List<AuditLog>.from(list);
  }

  void add(AuditLog record) => mockAuditLogs.insert(0, record);

  static bool matchesQuery(AuditLog a, String q) => _matchesQuery(a, q);

  static bool _matchesQuery(AuditLog a, String q) {
    if (a.userName.toLowerCase().contains(q)) return true;
    if ((a.patientName ?? '').toLowerCase().contains(q)) return true;
    if (a.description.toLowerCase().contains(q)) return true;
    if (actionTypeLabel(a.actionType).toLowerCase().contains(q)) return true;
    if (moduleTypeLabel(a.module).toLowerCase().contains(q)) return true;
    if (a.userRole.toLowerCase().contains(q)) return true;
    if ((a.ipAddress ?? '').toLowerCase().contains(q)) return true;
    if ((a.deviceInfo ?? '').toLowerCase().contains(q)) return true;
    return false;
  }
}
