import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/active_tenant_context_sync.dart';
import '../models/consent_record.dart';
import 'async_consent_repository_contract.dart';
import 'consent_list_filters.dart';
import 'consent_remote_mapper.dart';
import 'consent_repository_error_mapper.dart';
import 'consent_repository_failure.dart';

/// Supabase `consents` — doctor_admin / assistant_secretary RLS.
class SupabaseConsentRepository implements AsyncConsentRepositoryContract {
  SupabaseConsentRepository(this._client);

  factory SupabaseConsentRepository.fromSupabase() {
    return SupabaseConsentRepository(Supabase.instance.client);
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

  String? _createdByProfileId() {
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

  Future<void> _syncTenantForRead() async {
    try {
      await ActiveTenantContextSync.ensureSyncedBeforeWrite();
    } on ActiveTenantContextSyncException {
      throw const ConsentRepositoryException(
        ConsentRepositoryFailure.noActiveTenant,
      );
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
        .from(ConsentRemoteMapper.table)
        .select(ConsentRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<ConsentRecord> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => ConsentRemoteMapper.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ConsentRecord>> _fetchOrdered(
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
  Future<List<ConsentRecord>> getAll() async {
    return _guard(() async {
      await _syncTenantForRead();
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<ConsentRecord>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      await _syncTenantForRead();
      final tenantId = _requireTenantId();
      final pid = patientId.trim();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', pid));
    });
  }

  @override
  Future<ConsentRecord?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      await _syncTenantForRead();
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return ConsentRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<ConsentRecord>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getAll();

    final all = await getAll();
    final lower = q.toLowerCase();
    return all.where((c) => ConsentListFilters.matchesQuery(c, lower)).toList();
  }

  @override
  Future<ConsentRecord> add(ConsentRecord consent) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      final row = ConsentRemoteMapper.toInsertRow(
        tenantId: tenantId,
        consent: consent,
        createdByProfileId: _createdByProfileId(),
      );

      final inserted = await _client
          .from(ConsentRemoteMapper.table)
          .insert(row)
          .select(ConsentRemoteMapper.listSelectColumns)
          .single();

      return ConsentRemoteMapper.fromRow(Map<String, dynamic>.from(inserted));
    });
  }

  @override
  Future<ConsentRecord> update(ConsentRecord consent) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      final id = consent.id.trim();
      if (id.isEmpty) {
        throw const ConsentRepositoryException(
          ConsentRepositoryFailure.notFound,
        );
      }

      final updated = await _client
          .from(ConsentRemoteMapper.table)
          .update(ConsentRemoteMapper.toUpdateRow(consent))
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(ConsentRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const ConsentRepositoryException(
          ConsentRepositoryFailure.notFound,
        );
      }

      return ConsentRemoteMapper.fromRow(Map<String, dynamic>.from(updated));
    });
  }

  @override
  Future<int> countPending() async {
    return _guard(() async {
      await _syncTenantForRead();
      final tenantId = _requireTenantId();
      final result = await _client
          .from(ConsentRemoteMapper.table)
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('status', ConsentStatus.bekliyor.name)
          .isFilter('deleted_at', null)
          .count(CountOption.exact);
      return result.count;
    });
  }
}
