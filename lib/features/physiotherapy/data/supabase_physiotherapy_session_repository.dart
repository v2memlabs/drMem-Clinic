import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/physiotherapy_session_note.dart';
import 'async_physiotherapy_session_repository_contract.dart';
import 'physiotherapy_session_remote_mapper.dart';
import 'physiotherapy_session_repository_error_mapper.dart';
import 'physiotherapy_session_repository_failure.dart';

/// Supabase `physiotherapy_sessions` — doctor_admin / physiotherapist RLS.
class SupabasePhysiotherapySessionRepository
    implements AsyncPhysiotherapySessionRepositoryContract {
  SupabasePhysiotherapySessionRepository(this._client);

  factory SupabasePhysiotherapySessionRepository.fromSupabase() {
    return SupabasePhysiotherapySessionRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String _requireProfileId() {
    final id = ActiveTenantContextStore.current?.userId;
    if (id == null || id.trim().isEmpty) {
      throw const PhysiotherapySessionRepositoryException(
        PhysiotherapySessionRepositoryFailure.noActiveTenant,
      );
    }
    return id.trim();
  }

  Future<String> _resolveProfileIdForInsert() async {
    final authUserId = _client.auth.currentUser?.id.trim();
    if (authUserId != null && authUserId.isNotEmpty) {
      final row = await _client
          .from('profiles')
          .select('id')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      final profileId = row?['id']?.toString().trim();
      if (profileId != null && profileId.isNotEmpty) {
        return profileId;
      }
    }
    // Fallback: keep previous behavior for edge cases/tests.
    return _requireProfileId();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PhysiotherapySessionRepositoryException {
      rethrow;
    } catch (e) {
      throw PhysiotherapySessionRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(PhysiotherapySessionRemoteMapper.table)
        .select(PhysiotherapySessionRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<PhysiotherapySessionNote> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => PhysiotherapySessionRemoteMapper.fromRow(
              e as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<List<PhysiotherapySessionNote>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeQuery(tenantId));
    final rows = await query.order('session_date', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<PhysiotherapySessionNote>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<PhysiotherapySessionNote>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      final pid = patientId.trim();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', pid));
    });
  }

  @override
  Future<List<PhysiotherapySessionNote>> getByReferralId(
    String referralId,
  ) async {
    if (referralId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      final rid = referralId.trim();
      return _fetchOrdered(tenantId, (q) => q.eq('referral_id', rid));
    });
  }

  @override
  Future<PhysiotherapySessionNote?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return PhysiotherapySessionRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<PhysiotherapySessionNote> add(PhysiotherapySessionNote session) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final profileId = await _resolveProfileIdForInsert();
      final row = PhysiotherapySessionRemoteMapper.toInsertRow(
        tenantId: tenantId,
        session: session,
        physiotherapistProfileId: profileId,
      );

      final inserted = await _client
          .from(PhysiotherapySessionRemoteMapper.table)
          .insert(row)
          .select(PhysiotherapySessionRemoteMapper.listSelectColumns)
          .single();

      return PhysiotherapySessionRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }
}
