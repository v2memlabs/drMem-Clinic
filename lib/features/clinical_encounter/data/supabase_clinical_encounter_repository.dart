import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/active_tenant_context_sync.dart';
import '../models/clinical_encounter.dart';
import 'async_clinical_encounter_repository_contract.dart';
import 'clinical_encounter_remote_mapper.dart';
import 'clinical_encounter_repository_error_mapper.dart';
import 'clinical_encounter_repository_failure.dart';
import 'clinical_encounter_search_helper.dart';

/// Supabase `clinical_encounters` remote CRUD — [AsyncClinicalEncounterRepositoryContract].
///
/// **Doctor full-table path only** (`doctor_admin` + RLS). Asistan/FTR/hemşire
/// safe summary projection kullanmalı; bu sınıf genel amaçlı clinical repository
/// olarak kullanılmamalıdır.
///
/// UI/provider'a bağlı değil; varsayılan uygulama mock repository kullanır.
class SupabaseClinicalEncounterRepository
    implements AsyncClinicalEncounterRepositoryContract {
  SupabaseClinicalEncounterRepository(this._client);

  factory SupabaseClinicalEncounterRepository.fromSupabase() {
    return SupabaseClinicalEncounterRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  static const String _table = 'clinical_encounters';

  static const String _listSelectColumns =
      'id, protocol_number, tenant_id, patient_id, appointment_id, encounter_date, visit_type, '
      'status, diagnosis_summary, treatment_plan_summary, '
      'created_by, created_at, updated_at, deleted_at, '
      'patients(first_name, last_name)';

  static const String _detailSelectColumns =
      'id, protocol_number, tenant_id, patient_id, appointment_id, encounter_date, visit_type, '
      'status, diagnosis_summary, treatment_plan_summary, clinical_data, '
      'internal_doctor_note, created_by, created_at, updated_at, deleted_at, '
      'patients(first_name, last_name)';

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _currentProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeEncountersQuery(
    String tenantId,
    String selectColumns,
  ) {
    return _client
        .from(_table)
        .select(selectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ActiveTenantContextSyncException {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.noActiveTenant,
      );
    } catch (e) {
      throw ClinicalEncounterRepositoryErrorMapper.toException(e);
    }
  }

  Future<void> _syncTenantForWrite() async {
    try {
      await ActiveTenantContextSync.ensureSyncedBeforeWrite();
    } on ActiveTenantContextSyncException {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.noActiveTenant,
      );
    }
  }

  ClinicalEncounter _mapRow(Map<String, dynamic> row) {
    try {
      return ClinicalEncounterRemoteMapper.fromRow(row);
    } catch (_) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.invalidClinicalData,
      );
    }
  }

  List<ClinicalEncounter> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => _mapRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ClinicalEncounter>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeEncountersQuery(tenantId, _listSelectColumns));
    final rows = await query.order('encounter_date', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<ClinicalEncounter>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<ClinicalEncounter>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      final pid = patientId.trim();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', pid));
    });
  }

  @override
  Future<ClinicalEncounter?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeEncountersQuery(tenantId, _detailSelectColumns)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return _mapRow(row);
    });
  }

  @override
  Future<ClinicalEncounter?> getLatestByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final pid = patientId.trim();
      final rows = await _activeEncountersQuery(tenantId, _detailSelectColumns)
          .eq('patient_id', pid)
          .order('encounter_date', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      return _mapRow(rows.first);
    });
  }

  @override
  Future<List<ClinicalEncounter>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    // Remote v1: server-side search yok — MVP client-side (internalDoctorNote hariç).
    final all = await getAll();
    return ClinicalEncounterSearchHelper.filter(all, trimmed);
  }

  Future<int> countToday() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final range = _istanbulTodayRangeUtc();
      final result = await _client
          .from(_table)
          .select('id')
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .gte('created_at', range.startUtc.toIso8601String())
          .lt('created_at', range.endExclusiveUtc.toIso8601String())
          .count(CountOption.exact);
      return result.count;
    });
  }

  @override
  Future<ClinicalEncounter> add(ClinicalEncounter encounter) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      _assertValidPatientId(encounter.patientId);
      _assertValidEncounterDate(encounter.createdAt);

      final createdByProfileId = _currentProfileId();
      if (createdByProfileId == null || createdByProfileId.isEmpty) {
        throw const ClinicalEncounterRepositoryException(
          ClinicalEncounterRepositoryFailure.noActiveTenant,
        );
      }

      final insertRow = ClinicalEncounterRemoteMapper.toInsertRow(
        encounter,
        tenantId: tenantId,
        createdByProfileId: createdByProfileId,
      );

      final row = await _client
          .from(_table)
          .insert(insertRow)
          .select(_detailSelectColumns)
          .single();

      return _mapRow(row);
    });
  }

  @override
  Future<ClinicalEncounter> update(ClinicalEncounter encounter) async {
    return _guard(() async {
      await _syncTenantForWrite();
      final tenantId = _requireTenantId();
      _assertValidPatientId(encounter.patientId);
      _assertValidEncounterDate(encounter.createdAt);

      final updateRow = ClinicalEncounterRemoteMapper.toUpdateRow(encounter);

      final row = await _client
          .from(_table)
          .update(updateRow)
          .eq('id', encounter.id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(_detailSelectColumns)
          .maybeSingle();

      if (row == null) {
        throw const ClinicalEncounterRepositoryException(
          ClinicalEncounterRepositoryFailure.notFound,
        );
      }

      return _mapRow(row);
    });
  }

  @override
  Future<void> archiveEncounter(String id) async {
    await _guard(() async {
      final tenantId = _requireTenantId();
      final patch = ClinicalEncounterRemoteMapper.toArchiveRow();

      final row = await _client
          .from(_table)
          .update(patch)
          .eq('id', id.trim())
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw const ClinicalEncounterRepositoryException(
          ClinicalEncounterRepositoryFailure.notFound,
        );
      }
    });
  }

  void _assertValidPatientId(String patientId) {
    if (patientId.trim().isEmpty) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.patientNotFound,
      );
    }
  }

  void _assertValidEncounterDate(DateTime dateTime) {
    if (dateTime.year < 1900 || dateTime.year > 2100) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.invalidClinicalData,
      );
    }
  }

  ({DateTime startUtc, DateTime endExclusiveUtc}) _istanbulTodayRangeUtc() {
    const istanbulOffset = Duration(hours: 3);
    final istanbulNow = DateTime.now().toUtc().add(istanbulOffset);
    final istanbulStartAsUtc = DateTime.utc(
      istanbulNow.year,
      istanbulNow.month,
      istanbulNow.day,
    );
    final startUtc = istanbulStartAsUtc.subtract(istanbulOffset);
    return (
      startUtc: startUtc,
      endExclusiveUtc: startUtc.add(const Duration(days: 1)),
    );
  }
}
