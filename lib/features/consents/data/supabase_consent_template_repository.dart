import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/active_tenant_context_sync.dart';
import '../models/consent_template.dart';
import 'async_consent_template_repository_contract.dart';
import 'consent_repository_error_mapper.dart';
import 'consent_repository_failure.dart';
import 'consent_template_remote_mapper.dart';

/// Supabase `consent_templates` — doctor_admin / assistant_secretary RLS.
class SupabaseConsentTemplateRepository
    implements AsyncConsentTemplateRepositoryContract {
  SupabaseConsentTemplateRepository(this._client);

  factory SupabaseConsentTemplateRepository.fromSupabase() {
    return SupabaseConsentTemplateRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const ConsentRepositoryException(
        ConsentRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const ConsentRepositoryException(
        ConsentRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _ownerProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ConsentRepositoryException {
      rethrow;
    } on ActiveTenantContextSyncException {
      throw const ConsentRepositoryException(
        ConsentRepositoryFailure.noActiveTenant,
      );
    } catch (e) {
      throw ConsentRepositoryErrorMapper.toException(e);
    }
  }

  Future<void> _syncTenantForWrite() async {
    try {
      await ActiveTenantContextSync.ensureSyncedBeforeWrite();
    } on ActiveTenantContextSyncException {
      throw const ConsentRepositoryException(
        ConsentRepositoryFailure.noActiveTenant,
      );
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(ConsentTemplateRemoteMapper.table)
        .select(ConsentTemplateRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<ConsentTemplate> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => ConsentTemplateRemoteMapper.fromRow(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  List<ConsentTemplate> _applyFilters({
    required List<ConsentTemplate> items,
    String? query,
    String? categoryFilter,
    bool activeOnly = false,
  }) {
    var list = items;
    if (activeOnly) {
      list = list.where((t) => t.isActive).toList();
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      list = list.where((t) => t.category == categoryFilter).toList();
    }
    final q = (query ?? '').trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((t) => _matchesQuery(t, q)).toList();
  }

  bool _matchesQuery(ConsentTemplate t, String q) {
    if (t.title.toLowerCase().contains(q)) return true;
    if (t.category.toLowerCase().contains(q)) return true;
    if (t.description.toLowerCase().contains(q)) return true;
    if (t.documentFileName.toLowerCase().contains(q)) return true;
    if ((t.notes ?? '').toLowerCase().contains(q)) return true;
    return false;
  }

  @override
  Future<List<ConsentTemplate>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final rows = await _activeQuery(tenantId).order(
        'updated_at',
        ascending: false,
      );
      return _mapRows(rows);
    });
  }

  @override
  Future<ConsentTemplate?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return ConsentTemplateRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<ConsentTemplate>> getFiltered({
    String? query,
    String? categoryFilter,
    bool activeOnly = false,
  }) async {
    final all = await getAll();
    return _applyFilters(
      items: all,
      query: query,
      categoryFilter: categoryFilter,
      activeOnly: activeOnly,
    );
  }

  @override
  Future<ConsentTemplate> add(ConsentTemplate template) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      final row = ConsentTemplateRemoteMapper.toInsertRow(
        tenantId: tenantId,
        template: template,
        ownerProfileId: _ownerProfileId(),
      );

      final inserted = await _client
          .from(ConsentTemplateRemoteMapper.table)
          .insert(row)
          .select(ConsentTemplateRemoteMapper.listSelectColumns)
          .single();

      return ConsentTemplateRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<ConsentTemplate> update(ConsentTemplate template) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      final id = template.id.trim();
      if (id.isEmpty) {
        throw const ConsentRepositoryException(
          ConsentRepositoryFailure.notFound,
        );
      }

      final updated = await _client
          .from(ConsentTemplateRemoteMapper.table)
          .update(ConsentTemplateRemoteMapper.toUpdateRow(template))
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(ConsentTemplateRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const ConsentRepositoryException(
          ConsentRepositoryFailure.notFound,
        );
      }

      return ConsentTemplateRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }
}
