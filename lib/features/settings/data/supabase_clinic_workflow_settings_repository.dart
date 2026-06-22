import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/clinic_workflow_settings.dart';
import 'clinic_workflow_settings_mapper.dart';
import 'clinic_workflow_settings_repository.dart';

class SupabaseClinicWorkflowSettingsRepository
    implements ClinicWorkflowSettingsRepository {
  SupabaseClinicWorkflowSettingsRepository(this._client);

  factory SupabaseClinicWorkflowSettingsRepository.fromSupabase() {
    return SupabaseClinicWorkflowSettingsRepository(Supabase.instance.client);
  }

  static const String table = 'clinic_workflow_settings';

  final SupabaseClient _client;

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const ClinicWorkflowSettingsRepositoryException(
        'Supabase yapılandırması hazır değil.',
      );
    }
  }

  String _requireTenantId() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const ClinicWorkflowSettingsRepositoryException(
        'Aktif klinik bulunamadı.',
      );
    }
    return tenantId;
  }

  String? _updatedByProfileId() {
    final id = ActiveTenantContextStore.current?.profile.userId;
    if (id == null || id.trim().isEmpty) return null;
    return id.trim();
  }

  @override
  Future<ClinicWorkflowSettings?> load() async {
    final tenantId = _requireTenantId();
    try {
      final row = await _client
          .from(table)
          .select('schedule_json')
          .eq('tenant_id', tenantId)
          .maybeSingle();

      if (row == null) return null;
      final json = row['schedule_json'];
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return ClinicWorkflowSettingsMapper.fromJson(json);
    } catch (_) {
      throw const ClinicWorkflowSettingsRepositoryException(
        'Klinik işleyiş ayarları yüklenemedi.',
      );
    }
  }

  @override
  Future<void> save(ClinicWorkflowSettings settings) async {
    final tenantId = _requireTenantId();
    final payload = {
      'tenant_id': tenantId,
      'schedule_json': ClinicWorkflowSettingsMapper.toJson(settings),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_by': _updatedByProfileId(),
    };

    try {
      await _client.from(table).upsert(payload);
    } catch (_) {
      throw const ClinicWorkflowSettingsRepositoryException(
        'Klinik işleyiş ayarları kaydedilemedi.',
      );
    }
  }
}
