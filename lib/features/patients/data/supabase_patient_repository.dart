import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/patient.dart';
import 'async_patient_repository_contract.dart';
import '../../settings/data/tenant_settings_repository_provider.dart';
import 'patient_file_number_helper.dart';
import '../../patient_tags/data/patient_tag_repository_provider.dart';
import 'patient_remote_mapper.dart';
import 'patient_repository_error_mapper.dart';
import 'patient_repository_failure.dart';

/// Supabase `patients` remote CRUD — [AsyncPatientRepositoryContract].
///
/// UI/provider'a bağlı değil; yalnızca hazır implementasyon.
class SupabasePatientRepository implements AsyncPatientRepositoryContract {
  SupabasePatientRepository(this._client);

  /// Test ve ileride provider için enjekte edilebilir client.
  factory SupabasePatientRepository.fromSupabase() {
    return SupabasePatientRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  static const String _table = 'patients';

  static const String _selectColumns =
      'id, tenant_id, file_number, first_name, last_name, phone, birth_date, '
      'gender, national_id, insurance_type, status, created_at, updated_at, deleted_at';

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PatientRepositoryException(
        PatientRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PatientRepositoryException(
        PatientRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activePatientsQuery(
    String tenantId,
  ) {
    return _client
        .from(_table)
        .select(_selectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null);
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw PatientRepositoryErrorMapper.toException(e);
    }
  }

  List<Patient> _mapRows(List<dynamic> rows) {
    return rows
        .map((e) => PatientRemoteMapper.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Patient>> _enrichWithTagIds(List<Patient> patients) async {
    if (patients.isEmpty) return patients;
    try {
      final tagRepo = PatientTagRepositoryProvider.repository;
      final map = await tagRepo.getTagIdsByPatientIds(
        patients.map((p) => p.id).toList(),
      );
      return patients
          .map((p) => p.copyWith(tagIds: map[p.id] ?? const []))
          .toList();
    } catch (_) {
      return patients;
    }
  }

  @override
  Future<List<Patient>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final rows = await _activePatientsQuery(tenantId)
          .order(
            'last_name',
            ascending: true,
          )
          .order('first_name', ascending: true);
      return _enrichWithTagIds(_mapRows(rows));
    });
  }

  @override
  Future<List<Patient>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getAll();

    return _guard(() async {
      final tenantId = _requireTenantId();
      final pattern = '%${_escapeIlike(trimmed)}%';
      final orFilter = [
        'file_number.ilike.$pattern',
        'first_name.ilike.$pattern',
        'last_name.ilike.$pattern',
        'phone.ilike.$pattern',
        'national_id.ilike.$pattern',
      ].join(',');

      final rows = await _activePatientsQuery(tenantId)
          .or(orFilter)
          .order('last_name', ascending: true)
          .order('first_name', ascending: true);

      return _enrichWithTagIds(_mapRows(rows));
    });
  }

  @override
  Future<PatientListPage> listPage({
    String query = '',
    PatientListPageCursor? after,
    int limit = 50,
  }) async {
    return _guard(() async {
      _requireTenantId();
      final safeLimit = limit.clamp(1, 100).toInt();
      final rows = await _client.rpc(
        'search_patients_page_v1',
        params: {
          'p_query': query.trim().isEmpty ? null : query.trim(),
          'p_after_last_name': after?.lastName.trim().toLowerCase(),
          'p_after_first_name': after?.firstName.trim().toLowerCase(),
          'p_after_id': after?.id.trim(),
          'p_limit': safeLimit + 1,
        },
      );

      final mapped = _mapRows(rows as List<dynamic>);
      final enriched = await _enrichWithTagIds(mapped);
      final hasMore = enriched.length > safeLimit;
      final patients = hasMore ? enriched.take(safeLimit).toList() : enriched;

      return PatientListPage(
        patients: patients,
        nextCursor: hasMore && patients.isNotEmpty
            ? PatientListPageCursor.fromPatient(patients.last)
            : null,
      );
    });
  }

  @override
  Future<Patient?> getById(String id) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final row =
          await _activePatientsQuery(tenantId).eq('id', id).maybeSingle();
      if (row == null) return null;
      final patient = PatientRemoteMapper.fromRow(row);
      final enriched = await _enrichWithTagIds([patient]);
      return enriched.first;
    });
  }

  @override
  Future<String> getNameById(String id) async {
    final patient = await getById(id);
    return patient?.fullName ?? 'Bilinmeyen Hasta';
  }

  @override
  Future<int> count() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final result = await _client
          .from(_table)
          .select('id')
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .count(CountOption.exact);
      return result.count;
    });
  }

  @override
  Future<String> nextFileNumber() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final rows = await _client
          .from(_table)
          .select('file_number')
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null);

      final numbers = (rows as List<dynamic>)
          .map((e) =>
              (e as Map<String, dynamic>)['file_number'] as String? ?? '')
          .where((s) => s.isNotEmpty);

      final registrationSettings = await TenantSettingsRepositoryProvider
          .repository
          .loadPatientRegistrationSettings();
      return PatientFileNumberHelper.nextFromExisting(
        numbers,
        settings: registrationSettings,
      );
    });
  }

  @override
  Future<Patient> add(Patient patient) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final insertRow = PatientRemoteMapper.toInsertRow(
        patient,
        tenantId: tenantId,
      );

      final row = await _client
          .from(_table)
          .insert(insertRow)
          .select(_selectColumns)
          .single();

      return PatientRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<Patient> update(Patient patient) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final updateRow = PatientRemoteMapper.toUpdateRow(patient);

      final row = await _client
          .from(_table)
          .update(updateRow)
          .eq('id', patient.id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(_selectColumns)
          .maybeSingle();

      if (row == null) {
        throw const PatientRepositoryException(
          PatientRepositoryFailure.notFound,
        );
      }

      return PatientRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<void> archivePatient(String id) async {
    await _guard(() async {
      final tenantId = _requireTenantId();
      final patch = PatientRemoteMapper.toSoftDeleteRow();

      final row = await _client
          .from(_table)
          .update(patch)
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw const PatientRepositoryException(
          PatientRepositoryFailure.notFound,
        );
      }
    });
  }

  static String _escapeIlike(String input) {
    return input.replaceAllMapped(
      RegExp(r'[%_\\]'),
      (m) => '\\${m[0]}',
    );
  }
}
