import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/patient_file_metadata.dart';
import '../models/patient_file_metadata_enums.dart';
import 'patient_file_metadata_create_input.dart';
import 'patient_file_metadata_dto.dart';
import 'patient_file_metadata_mapper.dart';
import 'patient_file_metadata_remote_mapper.dart';
import 'patient_file_metadata_repository.dart';
import 'patient_file_metadata_repository_error_mapper.dart';
import 'patient_file_metadata_repository_failure.dart';

/// Supabase `patient_files` metadata CRUD — binary/storage yok.
///
/// Tablo: `patient_files` (Patient File/PDF Storage Metadata v1 migration).
/// `pdf_outputs` bu smoke paketinde ayrı tablo olarak bağlanmaz.
class SupabasePatientFileMetadataRepository
    implements PatientFileMetadataRepository {
  SupabasePatientFileMetadataRepository(this._client);

  factory SupabasePatientFileMetadataRepository.fromSupabase() {
    return SupabasePatientFileMetadataRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  @visibleForTesting
  static String get tableName => PatientFileMetadataRemoteMapper.table;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.noActiveTenant,
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
    } on PatientFileMetadataRepositoryException {
      rethrow;
    } catch (e) {
      throw PatientFileMetadataRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeMetadataQuery(
    String tenantId,
  ) {
    return _client
        .from(PatientFileMetadataRemoteMapper.table)
        .select(PatientFileMetadataRemoteMapper.selectColumns)
        .eq('tenant_id', tenantId)
        .isFilter('deleted_at', null)
        .neq('status', PatientFileStatus.deleted.dbValue);
  }

  List<PatientFileMetadata> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (row) => _mapRow(row as Map<String, dynamic>),
        )
        .toList();
  }

  PatientFileMetadata _mapRow(Map<String, dynamic> row) {
    try {
      return PatientFileMetadataMapper.fromDto(
        PatientFileMetadataDto.fromPatientFilesRow(row),
      );
    } on PatientFileMetadataRepositoryException {
      rethrow;
    } catch (_) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidRow,
      );
    }
  }

  Future<List<PatientFileMetadata>> _listFiltered(
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final rows = await build(_activeMetadataQuery(tenantId)).order(
        'created_at',
        ascending: false,
      );
      return _mapRows(rows);
    });
  }

  @override
  Future<List<PatientFileMetadata>> listPatientFiles({
    required String patientId,
  }) async {
    final pid = patientId.trim();
    if (pid.isEmpty) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidInput,
      );
    }

    return _listFiltered((q) => q.eq('patient_id', pid));
  }

  @override
  Future<List<PatientFileMetadata>> listTenantFiles({
    String? patientId,
  }) async {
    final pid = patientId?.trim() ?? '';
    if (pid.isNotEmpty) {
      return listPatientFiles(patientId: pid);
    }
    return _listFiltered((q) => q);
  }

  @override
  Future<PatientFileMetadata?> getPatientFileMetadata(String fileId) async {
    final id = fileId.trim();
    if (id.isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeMetadataQuery(tenantId)
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return _mapRow(row);
    });
  }

  @override
  Future<PatientFileMetadata> createPatientFileMetadata(
    PatientFileMetadataCreateInput input,
  ) async {
    return _guard(() async {
      final tenantId = _requireTenantId();

      try {
        input.validate();
      } on ArgumentError {
        throw const PatientFileMetadataRepositoryException(
          PatientFileMetadataRepositoryFailure.invalidInput,
        );
      }

      final insertRow = PatientFileMetadataRemoteMapper.toInsertRow(
        input: input,
        tenantId: tenantId,
        createdByProfileId: _createdByProfileId(),
      );

      final row = await _client
          .from(PatientFileMetadataRemoteMapper.table)
          .insert(insertRow)
          .select(PatientFileMetadataRemoteMapper.selectColumns)
          .single();

      return _mapRow(row);
    });
  }

  @override
  Future<void> archivePatientFile(String fileId) async {
    final id = fileId.trim();
    if (id.isEmpty) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidInput,
      );
    }

    await _guard(() async {
      final tenantId = _requireTenantId();
      final patch = PatientFileMetadataRemoteMapper.toArchiveRow();

      final row = await _client
          .from(PatientFileMetadataRemoteMapper.table)
          .update(patch)
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw const PatientFileMetadataRepositoryException(
          PatientFileMetadataRepositoryFailure.notFound,
        );
      }
    });
  }

  @override
  Future<List<PatientFileMetadata>> listEncounterFiles({
    required String encounterId,
  }) async {
    final eid = encounterId.trim();
    if (eid.isEmpty) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidInput,
      );
    }

    return _listFiltered((q) => q.eq('encounter_id', eid));
  }

  @override
  Future<List<PatientFileMetadata>> listAppointmentFiles({
    required String appointmentId,
  }) async {
    final aid = appointmentId.trim();
    if (aid.isEmpty) {
      throw const PatientFileMetadataRepositoryException(
        PatientFileMetadataRepositoryFailure.invalidInput,
      );
    }

    return _listFiltered((q) => q.eq('appointment_id', aid));
  }
}
