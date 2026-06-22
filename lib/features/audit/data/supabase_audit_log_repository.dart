import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/audit_log.dart';
import 'async_audit_log_repository_contract.dart';
import 'audit_log_remote_mapper.dart';
import 'audit_log_repository.dart';
import 'audit_log_repository_error_mapper.dart';
import 'audit_log_repository_failure.dart';

class SupabaseAuditLogRepository implements AsyncAuditLogRepositoryContract {
  SupabaseAuditLogRepository(this._client);

  factory SupabaseAuditLogRepository.fromSupabase() {
    return SupabaseAuditLogRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  static const int _listLimit = 250;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const AuditLogRepositoryException(
        AuditLogRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const AuditLogRepositoryException(
        AuditLogRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuditLogRepositoryException {
      rethrow;
    } catch (e) {
      throw AuditLogRepositoryErrorMapper.toException(e);
    }
  }

  List<AuditLog> _mapRows(List<dynamic> rows) {
    return rows.map((row) {
      try {
        return AuditLogRemoteMapper.fromRow(Map<String, dynamic>.from(row as Map));
      } catch (_) {
        throw const AuditLogRepositoryException(
          AuditLogRepositoryFailure.invalidRow,
        );
      }
    }).toList();
  }

  Future<List<AuditLog>> _fetch({
    required String tenantId,
    String? patientId,
  }) async {
    var query = _client
        .from(AuditLogRemoteMapper.table)
        .select(AuditLogRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId);

    if (patientId != null && patientId.trim().isNotEmpty) {
      query = query.eq('patient_id', patientId.trim());
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(_listLimit);

    return _mapRows(rows);
  }

  @override
  Future<List<AuditLog>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetch(tenantId: tenantId);
    });
  }

  @override
  Future<List<AuditLog>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetch(tenantId: tenantId, patientId: patientId);
    });
  }

  @override
  Future<AuditLog?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _client
          .from(AuditLogRemoteMapper.table)
          .select(AuditLogRemoteMapper.listSelectColumns)
          .eq('tenant_id', tenantId)
          .eq('id', id.trim())
          .maybeSingle();

      if (row == null) return null;
      return AuditLogRemoteMapper.fromRow(Map<String, dynamic>.from(row));
    });
  }

  @override
  Future<List<AuditLog>> getFiltered({
    String? patientId,
    String? query,
    ActionType? actionTypeFilter,
    ModuleType? moduleFilter,
  }) async {
    Iterable<AuditLog> list;
    final q = query?.trim().toLowerCase() ?? '';

    if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (actionTypeFilter != null) {
      list = list.where((a) => a.actionType == actionTypeFilter);
    }
    if (moduleFilter != null) {
      list = list.where((a) => a.module == moduleFilter);
    }
    if (q.isNotEmpty) {
      list = list.where((a) => AuditLogRepository.matchesQuery(a, q));
    }

    return List<AuditLog>.from(list);
  }
}
