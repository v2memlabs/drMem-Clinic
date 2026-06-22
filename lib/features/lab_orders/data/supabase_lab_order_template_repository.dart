import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/lab_order_template.dart';
import 'async_lab_order_template_repository_contract.dart';
import 'lab_order_template_remote_mapper.dart';
import 'lab_order_template_repository_error_mapper.dart';
import 'lab_order_template_repository_failure.dart';

class SupabaseLabOrderTemplateRepository
    implements AsyncLabOrderTemplateRepositoryContract {
  SupabaseLabOrderTemplateRepository(this._client);

  factory SupabaseLabOrderTemplateRepository.fromSupabase() {
    return SupabaseLabOrderTemplateRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.noActiveTenant,
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
    } on LabOrderTemplateRepositoryException {
      rethrow;
    } catch (e) {
      throw LabOrderTemplateRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(LabOrderTemplateRemoteMapper.table)
        .select(LabOrderTemplateRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<LabOrderTemplate> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => LabOrderTemplateRemoteMapper.fromRow(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<List<LabOrderTemplate>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final rows = await _activeQuery(tenantId).order(
        'created_at',
        ascending: false,
      );
      return _mapRows(rows);
    });
  }

  @override
  Future<LabOrderTemplate?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return LabOrderTemplateRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<LabOrderTemplate>> search(String query) async {
    final q = query.trim().toLowerCase();
    final all = await getAll();
    if (q.isEmpty) return all;
    return all.where((t) {
      if (t.name.toLowerCase().contains(q)) return true;
      if ((t.description ?? '').toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  Future<LabOrderTemplate> create(LabOrderTemplate template) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = LabOrderTemplateRemoteMapper.toInsertRow(
        tenantId: tenantId,
        template: template,
        createdByProfileId: _createdByProfileId(),
        createdByDisplay: _createdByDisplay(),
      );

      final inserted = await _client
          .from(LabOrderTemplateRemoteMapper.table)
          .insert(row)
          .select(LabOrderTemplateRemoteMapper.listSelectColumns)
          .single();

      return LabOrderTemplateRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<LabOrderTemplate> update(LabOrderTemplate template) async {
    if (template.id.trim().isEmpty) {
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.invalidRow,
      );
    }

    return _guard(() async {
      final tenantId = _requireTenantId();
      final updated = await _client
          .from(LabOrderTemplateRemoteMapper.table)
          .update(LabOrderTemplateRemoteMapper.toUpdateRow(template))
          .eq('tenant_id', tenantId)
          .eq('id', template.id.trim())
          .isFilter('deleted_at', null)
          .select(LabOrderTemplateRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const LabOrderTemplateRepositoryException(
          LabOrderTemplateRepositoryFailure.notFound,
        );
      }

      return LabOrderTemplateRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    if (id.trim().isEmpty) {
      throw const LabOrderTemplateRepositoryException(
        LabOrderTemplateRepositoryFailure.notFound,
      );
    }

    await _guard(() async {
      final tenantId = _requireTenantId();
      final patch = LabOrderTemplateRemoteMapper.toArchiveRow();

      final row = await _client
          .from(LabOrderTemplateRemoteMapper.table)
          .update(patch)
          .eq('tenant_id', tenantId)
          .eq('id', id.trim())
          .isFilter('deleted_at', null)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw const LabOrderTemplateRepositoryException(
          LabOrderTemplateRepositoryFailure.notFound,
        );
      }
    });
  }
}
