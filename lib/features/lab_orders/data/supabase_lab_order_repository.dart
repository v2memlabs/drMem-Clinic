import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/lab_order.dart';
import 'async_lab_order_repository_contract.dart';
import 'lab_order_remote_mapper.dart';
import 'lab_order_repository.dart';
import 'lab_order_repository_error_mapper.dart';
import 'lab_order_repository_failure.dart';

class SupabaseLabOrderRepository implements AsyncLabOrderRepositoryContract {
  SupabaseLabOrderRepository(this._client);

  factory SupabaseLabOrderRepository.fromSupabase() {
    return SupabaseLabOrderRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _createdByProfileId() {
    final id = ActiveTenantContextStore.current?.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  String? _createdByDisplay() {
    final name = ActiveTenantContextStore.current?.profile.displayName;
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on LabOrderRepositoryException {
      rethrow;
    } catch (e) {
      throw LabOrderRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(LabOrderRemoteMapper.table)
        .select(LabOrderRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<LabOrder> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => LabOrderRemoteMapper.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LabOrder>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeQuery(tenantId));
    final rows = await query.order('created_at', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<LabOrder>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<LabOrder>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(
        tenantId,
        (q) => q.eq('patient_id', patientId.trim()),
      );
    });
  }

  @override
  Future<LabOrder?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return LabOrderRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<LabOrder>> getFiltered({
    String? patientId,
    String? query,
    LabOrderStatus? statusFilter,
  }) async {
    Iterable<LabOrder> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      final all = await getAll();
      final lower = q.toLowerCase();
      list = all.where((o) => LabOrderRepository.matchesQuery(o, lower));
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (statusFilter != null) {
      list = list.where((o) => o.status == statusFilter);
    }
    return List<LabOrder>.from(list);
  }

  @override
  Future<LabOrder> create(LabOrder order) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = LabOrderRemoteMapper.toInsertRow(
        tenantId: tenantId,
        order: order,
        createdByProfileId: _createdByProfileId(),
        createdByDisplay: _createdByDisplay(),
      );

      final inserted = await _client
          .from(LabOrderRemoteMapper.table)
          .insert(row)
          .select(LabOrderRemoteMapper.listSelectColumns)
          .single();

      return LabOrderRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<LabOrder> update(LabOrder order) async {
    if (order.id.trim().isEmpty) {
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.invalidRow,
      );
    }

    return _guard(() async {
      final tenantId = _requireTenantId();
      final updated = await _client
          .from(LabOrderRemoteMapper.table)
          .update(LabOrderRemoteMapper.toUpdateRow(order))
          .eq('tenant_id', tenantId)
          .eq('id', order.id.trim())
          .isFilter('deleted_at', null)
          .select(LabOrderRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const LabOrderRepositoryException(
          LabOrderRepositoryFailure.notFound,
        );
      }
      return LabOrderRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    if (id.trim().isEmpty) {
      throw const LabOrderRepositoryException(
        LabOrderRepositoryFailure.notFound,
      );
    }

    await _guard(() async {
      final tenantId = _requireTenantId();
      final patch = LabOrderRemoteMapper.toArchiveRow();

      final row = await _client
          .from(LabOrderRemoteMapper.table)
          .update(patch)
          .eq('tenant_id', tenantId)
          .eq('id', id.trim())
          .isFilter('deleted_at', null)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw const LabOrderRepositoryException(
          LabOrderRepositoryFailure.notFound,
        );
      }
    });
  }
}
