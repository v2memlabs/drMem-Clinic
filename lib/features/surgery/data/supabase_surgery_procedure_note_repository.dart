import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/surgery_procedure_note.dart';
import 'async_surgery_procedure_note_repository_contract.dart';
import 'surgery_procedure_note_remote_mapper.dart';
import 'surgery_procedure_note_repository_error_mapper.dart';
import 'surgery_procedure_note_repository_failure.dart';
import 'surgery_repository.dart';

class SupabaseSurgeryProcedureNoteRepository
    implements AsyncSurgeryProcedureNoteRepositoryContract {
  SupabaseSurgeryProcedureNoteRepository(this._client);

  factory SupabaseSurgeryProcedureNoteRepository.fromSupabase() {
    return SupabaseSurgeryProcedureNoteRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.notConfigured,
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.noActiveTenant,
      );
    }
    return tenantId;
  }

  String? _createdByProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  String? _recordedByDisplay() {
    final name = ActiveTenantContextStore.current?.profile.displayName;
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on SurgeryProcedureNoteRepositoryException {
      rethrow;
    } catch (e) {
      throw SurgeryProcedureNoteRepositoryErrorMapper.toException(e);
    }
  }

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _activeQuery(
    String tenantId,
  ) {
    final profileId = _createdByProfileId();
    if (profileId == null || profileId.isEmpty) {
      throw const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.noActiveTenant,
      );
    }

    return _client
        .from(SurgeryProcedureNoteRemoteMapper.table)
        .select(SurgeryProcedureNoteRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .eq('created_by', profileId)
        .isFilter('deleted_at', null);
  }

  List<SurgeryProcedureNote> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => SurgeryProcedureNoteRemoteMapper.fromRow(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<SurgeryProcedureNote>> _fetchOrdered(
    String tenantId,
    PostgrestFilterBuilder<List<Map<String, dynamic>>> Function(
      PostgrestFilterBuilder<List<Map<String, dynamic>>>,
    ) build,
  ) async {
    final query = build(_activeQuery(tenantId));
    final rows = await query
        .order('procedure_date', ascending: false)
        .order('created_at', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<List<SurgeryProcedureNote>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q);
    });
  }

  @override
  Future<List<SurgeryProcedureNote>> getByPatientId(String patientId) async {
    if (patientId.trim().isEmpty) return const [];

    return _guard(() async {
      final tenantId = _requireTenantId();
      return _fetchOrdered(tenantId, (q) => q.eq('patient_id', patientId.trim()));
    });
  }

  @override
  Future<SurgeryProcedureNote?> getById(String id) async {
    if (id.trim().isEmpty) return null;

    return _guard(() async {
      final tenantId = _requireTenantId();
      final row = await _activeQuery(tenantId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return SurgeryProcedureNoteRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<SurgeryProcedureNote>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return getAll();

    final all = await getAll();
    final lower = q.toLowerCase();
    return all.where((n) => SurgeryRepository.matchesQuery(n, lower)).toList();
  }

  @override
  Future<SurgeryProcedureNote> create(SurgeryProcedureNote note) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final createdBy = _createdByProfileId();
      if (createdBy == null || createdBy.isEmpty) {
        throw const SurgeryProcedureNoteRepositoryException(
          SurgeryProcedureNoteRepositoryFailure.noActiveTenant,
        );
      }
      final row = SurgeryProcedureNoteRemoteMapper.toInsertRow(
        tenantId: tenantId,
        note: note,
        createdByProfileId: createdBy,
        recordedByDisplay: _recordedByDisplay(),
      );

      final inserted = await _client
          .from(SurgeryProcedureNoteRemoteMapper.table)
          .insert(row)
          .select(SurgeryProcedureNoteRemoteMapper.listSelectColumns)
          .single();

      return SurgeryProcedureNoteRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<SurgeryProcedureNote> update(SurgeryProcedureNote note) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final trimmedId = note.id.trim();
      if (trimmedId.isEmpty) {
        throw const SurgeryProcedureNoteRepositoryException(
          SurgeryProcedureNoteRepositoryFailure.notFound,
        );
      }

      final row = SurgeryProcedureNoteRemoteMapper.toUpdateRow(note);
      final updated = await _client
          .from(SurgeryProcedureNoteRemoteMapper.table)
          .update(row)
          .eq('id', trimmedId)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(SurgeryProcedureNoteRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const SurgeryProcedureNoteRepositoryException(
          SurgeryProcedureNoteRepositoryFailure.notFound,
        );
      }

      return SurgeryProcedureNoteRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }

  @override
  Future<SurgeryProcedureNote> updateNotes(String id, String notes) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final trimmedId = id.trim();
      if (trimmedId.isEmpty) {
        throw const SurgeryProcedureNoteRepositoryException(
          SurgeryProcedureNoteRepositoryFailure.notFound,
        );
      }

      final updated = await _client
          .from(SurgeryProcedureNoteRemoteMapper.table)
          .update({'notes': notes.trim()})
          .eq('id', trimmedId)
          .eq('tenant_id', tenantId)
          .isFilter('deleted_at', null)
          .select(SurgeryProcedureNoteRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const SurgeryProcedureNoteRepositoryException(
          SurgeryProcedureNoteRepositoryFailure.notFound,
        );
      }

      return SurgeryProcedureNoteRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }
}
