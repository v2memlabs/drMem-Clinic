import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/radiology_order.dart';
import 'async_radiology_order_repository_contract.dart';
import 'radiology_order_remote_mapper.dart';
import 'radiology_order_repository.dart';
import 'radiology_order_repository_error_mapper.dart';
import 'radiology_order_repository_failure.dart';

class SupabaseRadiologyOrderRepository
    implements AsyncRadiologyOrderRepositoryContract {
  SupabaseRadiologyOrderRepository(this._client);

  factory SupabaseRadiologyOrderRepository.fromSupabase() {
    return SupabaseRadiologyOrderRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.noActiveTenant,
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
    } on RadiologyOrderRepositoryException {
      rethrow;
    } catch (e) {
      throw RadiologyOrderRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(RadiologyOrderRemoteMapper.table)
        .select(RadiologyOrderRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<RadiologyOrder> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => RadiologyOrderRemoteMapper.fromRow(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<RadiologyOrder>> _fetchOrdered(
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
  Future<List<RadiologyOrder>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<RadiologyOrder>> getByPatientId(String patientId) async {
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
  Future<RadiologyOrder?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return RadiologyOrderRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<RadiologyOrder>> getFiltered({
    String? patientId,
    String? query,
    RadiologyOrderStatus? statusFilter,
  }) async {
    Iterable<RadiologyOrder> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      final all = await getAll();
      final lower = q.toLowerCase();
      list = all.where((o) => RadiologyOrderRepository.matchesQuery(o, lower));
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (statusFilter != null) {
      list = list.where((o) => o.status == statusFilter);
    }
    return List<RadiologyOrder>.from(list);
  }

  @override
  Future<RadiologyOrder> create(RadiologyOrder order) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = RadiologyOrderRemoteMapper.toInsertRow(
        tenantId: tenantId,
        order: order,
        createdByProfileId: _createdByProfileId(),
        createdByDisplay: _createdByDisplay(),
      );

      final inserted = await _client
          .from(RadiologyOrderRemoteMapper.table)
          .insert(row)
          .select(RadiologyOrderRemoteMapper.listSelectColumns)
          .single();

      return RadiologyOrderRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<RadiologyOrder> update(RadiologyOrder order) async {
    if (order.id.trim().isEmpty) {
      throw const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.invalidRow,
      );
    }

    return _guard(() async {
      final tenantId = _requireTenantId();
      final updated = await _client
          .from(RadiologyOrderRemoteMapper.table)
          .update(RadiologyOrderRemoteMapper.toUpdateRow(order))
          .eq('tenant_id', tenantId)
          .eq('id', order.id.trim())
          .isFilter('deleted_at', null)
          .select(RadiologyOrderRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const RadiologyOrderRepositoryException(
          RadiologyOrderRepositoryFailure.notFound,
        );
      }
      return RadiologyOrderRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    if (id.trim().isEmpty) {
      throw const RadiologyOrderRepositoryException(
        RadiologyOrderRepositoryFailure.invalidRow,
      );
    }

    await _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _client
          .from(RadiologyOrderRemoteMapper.table)
          .update(RadiologyOrderRemoteMapper.toSoftDeleteRow())
          .eq('tenant_id', tenantId)
          .eq('id', id.trim())
          .isFilter('deleted_at', null)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw const RadiologyOrderRepositoryException(
          RadiologyOrderRepositoryFailure.notFound,
        );
      }
    });
  }
}
