import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/active_tenant_context_sync.dart';
import '../models/physiotherapy_referral.dart';
import 'async_physiotherapy_referral_repository_contract.dart';
import 'physiotherapy_referral_remote_mapper.dart';
import 'physiotherapy_referral_repository_error_mapper.dart';
import 'physiotherapy_referral_list_filters.dart';
import 'physiotherapy_referral_repository_failure.dart';

/// Supabase `physiotherapy_referrals` — doctor_admin / physiotherapist RLS.
class SupabasePhysiotherapyReferralRepository
    implements AsyncPhysiotherapyReferralRepositoryContract {
  SupabasePhysiotherapyReferralRepository(this._client);

  factory SupabasePhysiotherapyReferralRepository.fromSupabase() {
    return SupabasePhysiotherapyReferralRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String _requireProfileId() {
    final id = ActiveTenantContextStore.current?.userId;
    if (id == null || id.trim().isEmpty) {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.noActiveTenant,
      );
    }
    return id.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PhysiotherapyReferralRepositoryException {
      rethrow;
    } on ActiveTenantContextSyncException {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.noActiveTenant,
      );
    } catch (e) {
      throw PhysiotherapyReferralRepositoryErrorMapper.toException(e);
    }
  }

  Future<void> _syncTenantForWrite() async {
    try {
      await ActiveTenantContextSync.ensureSyncedBeforeWrite();
    } on ActiveTenantContextSyncException {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.noActiveTenant,
      );
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(PhysiotherapyReferralRemoteMapper.table)
        .select(PhysiotherapyReferralRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<PhysiotherapyReferral> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => PhysiotherapyReferralRemoteMapper.fromRow(
              e as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<List<PhysiotherapyReferral>> _fetchOrdered(
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
  Future<List<PhysiotherapyReferral>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<PhysiotherapyReferral>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      final pid = patientId.trim();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', pid));
    });
  }

  @override
  Future<PhysiotherapyReferral?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return PhysiotherapyReferralRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<PhysiotherapyReferral>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getAll();
    final all = await getAll();
    return PhysiotherapyReferralListFilters.matchesQueryList(all, q);
  }

  @override
  Future<List<PhysiotherapyReferral>> getFiltered({
    String? patientId,
    String? query,
    ReferralStatus? statusEnumFilter,
    String? physiotherapistFilter,
  }) async {
    Iterable<PhysiotherapyReferral> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      list = await search(q);
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (statusEnumFilter != null) {
      list = list.where((r) => r.status == statusEnumFilter);
    }
    if (physiotherapistFilter != null && physiotherapistFilter.isNotEmpty) {
      final pf = physiotherapistFilter.toLowerCase();
      list = list.where(
        (r) => r.physiotherapistName.toLowerCase().contains(pf),
      );
    }

    return List<PhysiotherapyReferral>.from(list);
  }

  Future<int> countByStatus(ReferralStatus status) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final result = await _client
          .from(PhysiotherapyReferralRemoteMapper.table)
          .select('id')
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .eq('status', status.name)
          .count(CountOption.exact);
      return result.count;
    });
  }

  /// Atanmış fizyoterapist için randevu bekleyen yeni yönlendirme sayısı.
  Future<int> countPendingForAssignedPhysiotherapist() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final profileId = _requireProfileId();
      final result = await _client
          .from(PhysiotherapyReferralRemoteMapper.table)
          .select('id')
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .eq('status', ReferralStatus.yeni.name)
          .eq('assigned_physiotherapist_profile_id', profileId)
          .isFilter('appointment_id', null)
          .count(CountOption.exact);
      return result.count;
    });
  }

  @override
  Future<PhysiotherapyReferral> add(PhysiotherapyReferral referral) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      final profileId = _requireProfileId();
      final row = PhysiotherapyReferralRemoteMapper.toInsertRow(
        tenantId: tenantId,
        referral: referral,
        referredByProfileId: profileId,
        assignedPhysiotherapistProfileId:
            referral.assignedPhysiotherapistProfileId,
      );

      final inserted = await _client
          .from(PhysiotherapyReferralRemoteMapper.table)
          .insert(row)
          .select(PhysiotherapyReferralRemoteMapper.listSelectColumns)
          .single();

      return PhysiotherapyReferralRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<PhysiotherapyReferral> updateSafeFields(
    String id,
    PhysiotherapyReferralSafeUpdate update,
  ) async {
    if (id.trim().isEmpty || update.isEmpty) {
      throw const PhysiotherapyReferralRepositoryException(
        PhysiotherapyReferralRepositoryFailure.invalidRow,
      );
    }

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = PhysiotherapyReferralRemoteMapper.toSafeUpdateRow(update);
      if (row.isEmpty) {
        throw const PhysiotherapyReferralRepositoryException(
          PhysiotherapyReferralRepositoryFailure.invalidRow,
        );
      }

      final updated = await _client
          .from(PhysiotherapyReferralRemoteMapper.table)
          .update(row)
          .eq('tenant_id', tenantId)
          .eq('id', id.trim())
          .isFilter('deleted_at', null)
          .select(PhysiotherapyReferralRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const PhysiotherapyReferralRepositoryException(
          PhysiotherapyReferralRepositoryFailure.notFound,
        );
      }

      return PhysiotherapyReferralRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }
}
