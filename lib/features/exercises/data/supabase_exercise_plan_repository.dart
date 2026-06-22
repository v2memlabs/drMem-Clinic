import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/exercise_plan.dart';
import 'async_exercise_plan_repository_contract.dart';
import 'exercise_plan_remote_mapper.dart';
import 'exercise_plan_repository.dart';
import 'exercise_plan_repository_error_mapper.dart';
import 'exercise_plan_repository_failure.dart';

class SupabaseExercisePlanRepository
    implements AsyncExercisePlanRepositoryContract {
  SupabaseExercisePlanRepository(this._client);

  factory SupabaseExercisePlanRepository.fromSupabase() {
    return SupabaseExercisePlanRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.noActiveTenant,
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
    } on ExercisePlanRepositoryException {
      rethrow;
    } catch (e) {
      throw ExercisePlanRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    return _client
        .from(ExercisePlanRemoteMapper.table)
        .select(ExercisePlanRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  List<ExercisePlan> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => ExercisePlanRemoteMapper.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExercisePlan>> _fetchOrdered(
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
  Future<List<ExercisePlan>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<ExercisePlan>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(
          tenantId, (q) => q.eq('patient_id', patientId.trim()));
    });
  }

  @override
  Future<List<ExercisePlan>> getByReferralId(String referralId) async {
    if (referralId.trim().isEmpty) return const [];
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(
          tenantId, (q) => q.eq('referral_id', referralId.trim()));
    });
  }

  @override
  Future<ExercisePlan?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activeQuery(tenantId).eq('id', id.trim()).maybeSingle();
      if (row == null) return null;
      return ExercisePlanRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<ExercisePlan>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getAll();
    final all = await getAll();
    final lower = q.toLowerCase();
    return all
        .where((p) => ExercisePlanRepository.matchesQuery(p, lower))
        .toList();
  }

  @override
  Future<List<ExercisePlan>> getFiltered({
    String? patientId,
    String? query,
    ExercisePlanPhase? phaseEnumFilter,
    ExercisePlanStatus? statusEnumFilter,
    bool? approvedByDoctor,
  }) async {
    Iterable<ExercisePlan> list;
    final q = query?.trim() ?? '';

    if (q.isNotEmpty) {
      list = await search(q);
    } else if (patientId != null && patientId.trim().isNotEmpty) {
      list = await getByPatientId(patientId.trim());
    } else {
      list = await getAll();
    }

    if (phaseEnumFilter != null) {
      list = list.where((p) => p.phase == phaseEnumFilter);
    }
    if (statusEnumFilter != null) {
      list = list.where((p) => p.status == statusEnumFilter);
    }
    if (approvedByDoctor != null) {
      list = list.where((p) => p.doctorApproved == approvedByDoctor);
    }
    return List<ExercisePlan>.from(list);
  }

  @override
  Future<ExercisePlan> create(ExercisePlan plan) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = ExercisePlanRemoteMapper.toInsertRow(
        tenantId: tenantId,
        plan: plan,
        createdByProfileId: _createdByProfileId(),
        createdByDisplay: _createdByDisplay(),
      );

      final inserted = await _client
          .from(ExercisePlanRemoteMapper.table)
          .insert(row)
          .select(ExercisePlanRemoteMapper.listSelectColumns)
          .single();

      return ExercisePlanRemoteMapper.fromRow(
          Map<String, dynamic>.from(inserted));
    });
  }

  @override
  Future<ExercisePlan> approveByDoctor(String id) async {
    if (id.trim().isEmpty) {
      throw const ExercisePlanRepositoryException(
        ExercisePlanRepositoryFailure.invalidRow,
      );
    }

    return _guard(() async {
      final tenantId = _requireTenantId();
      final updated = await _client
          .from(ExercisePlanRemoteMapper.table)
          .update({
            'doctor_approved': true,
            'status': ExercisePlanStatus.aktif.name,
          })
          .eq('tenant_id', tenantId)
          .eq('id', id.trim())
          .isFilter('deleted_at', null)
          .select(ExercisePlanRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const ExercisePlanRepositoryException(
          ExercisePlanRepositoryFailure.notFound,
        );
      }
      return ExercisePlanRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }
}
