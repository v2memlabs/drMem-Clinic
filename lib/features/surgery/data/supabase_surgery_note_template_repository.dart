import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/surgery_note_template.dart';
import 'async_surgery_note_template_repository_contract.dart';
import 'surgery_note_template_remote_mapper.dart';
import 'surgery_procedure_note_repository_error_mapper.dart';
import 'surgery_procedure_note_repository_failure.dart';

class SupabaseSurgeryNoteTemplateRepository
    implements AsyncSurgeryNoteTemplateRepositoryContract {
  SupabaseSurgeryNoteTemplateRepository(this._client);

  factory SupabaseSurgeryNoteTemplateRepository.fromSupabase() {
    return SupabaseSurgeryNoteTemplateRepository(Supabase.instance.client);
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

  String _requireProfileId() {
    final profileId = ActiveTenantContextStore.current?.profile.userId;
    if (profileId == null || profileId.isEmpty) {
      throw const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.noActiveTenant,
      );
    }
    return profileId;
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
    String profileId,
  ) {
    return _client
        .from(SurgeryNoteTemplateRemoteMapper.table)
        .select(SurgeryNoteTemplateRemoteMapper.listSelectColumns)
        .eq('tenant_id', tenantId)
        .eq('profile_id', profileId)
        .isFilter('deleted_at', null);
  }

  List<SurgeryNoteTemplate> _mapRows(List<dynamic> rows) {
    return rows
        .map(
          (e) => SurgeryNoteTemplateRemoteMapper.fromRow(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<List<SurgeryNoteTemplate>> getAll() async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final profileId = _requireProfileId();
      final rows = await _activeQuery(tenantId, profileId).order(
        'updated_at',
        ascending: false,
      );
      return _mapRows(rows);
    });
  }

  @override
  Future<SurgeryNoteTemplate?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return _guard(() async {
      final tenantId = _requireTenantId();
      final profileId = _requireProfileId();
      final row = await _activeQuery(tenantId, profileId)
          .eq('id', id.trim())
          .maybeSingle();
      if (row == null) return null;
      return SurgeryNoteTemplateRemoteMapper.fromRow(row);
    });
  }

  @override
  Future<List<SurgeryNoteTemplate>> search(String query) async {
    final q = query.trim().toLowerCase();
    final all = await getAll();
    if (q.isEmpty) return all;
    return all.where((t) {
      if (t.name.toLowerCase().contains(q)) return true;
      if (t.description.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  Future<SurgeryNoteTemplate> create(SurgeryNoteTemplate template) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final profileId = _requireProfileId();
      final row = SurgeryNoteTemplateRemoteMapper.toInsertRow(
        tenantId: tenantId,
        profileId: profileId,
        template: template,
      );

      final inserted = await _client
          .from(SurgeryNoteTemplateRemoteMapper.table)
          .insert(row)
          .select(SurgeryNoteTemplateRemoteMapper.listSelectColumns)
          .single();

      return SurgeryNoteTemplateRemoteMapper.fromRow(
        Map<String, dynamic>.from(inserted),
      );
    });
  }

  @override
  Future<SurgeryNoteTemplate> update(SurgeryNoteTemplate template) async {
    return _guard(() async {
      final tenantId = _requireTenantId();
      final profileId = _requireProfileId();
      final updated = await _client
          .from(SurgeryNoteTemplateRemoteMapper.table)
          .update(SurgeryNoteTemplateRemoteMapper.toUpdateRow(template))
          .eq('id', template.id.trim())
          .eq('tenant_id', tenantId)
          .eq('profile_id', profileId)
          .isFilter('deleted_at', null)
          .select(SurgeryNoteTemplateRemoteMapper.listSelectColumns)
          .maybeSingle();

      if (updated == null) {
        throw const SurgeryProcedureNoteRepositoryException(
          SurgeryProcedureNoteRepositoryFailure.notFound,
        );
      }

      return SurgeryNoteTemplateRemoteMapper.fromRow(
        Map<String, dynamic>.from(updated),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    if (id.trim().isEmpty) {
      throw const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.notFound,
      );
    }

    await _guard(() async {
      final tenantId = _requireTenantId();
      final profileId = _requireProfileId();
      await _client
          .from(SurgeryNoteTemplateRemoteMapper.table)
          .delete()
          .eq('id', id.trim())
          .eq('tenant_id', tenantId)
          .eq('profile_id', profileId);
    });
  }
}
