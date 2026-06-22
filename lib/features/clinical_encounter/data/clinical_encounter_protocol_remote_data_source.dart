import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/active_tenant_context_sync.dart';
import 'clinical_encounter_repository_error_mapper.dart';
import 'clinical_encounter_repository_failure.dart';

/// Tenant geneli protokol numarası — `next_clinical_encounter_protocol_number` RPC.
abstract final class ClinicalEncounterProtocolRemoteDataSource {
  static Future<String> nextForActiveTenant({required int year}) async {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured ||
        !SupabaseClientInitializer.isInitialized) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.notConfigured,
      );
    }

    await ActiveTenantContextSync.ensureSyncedBeforeWrite();

    final tenantId = ActiveTenantContextStore.current?.tenantId.trim();
    if (tenantId == null || tenantId.isEmpty) {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.noActiveTenant,
      );
    }

    try {
      final result = await Supabase.instance.client.rpc(
        'next_clinical_encounter_protocol_number',
        params: {
          'p_tenant_id': tenantId,
          'p_year': year,
        },
      );
      final protocol = result?.toString().trim() ?? '';
      if (protocol.isEmpty) {
        throw const ClinicalEncounterRepositoryException(
          ClinicalEncounterRepositoryFailure.invalidClinicalData,
        );
      }
      return protocol;
    } on ClinicalEncounterRepositoryException {
      rethrow;
    } on ActiveTenantContextSyncException {
      throw const ClinicalEncounterRepositoryException(
        ClinicalEncounterRepositoryFailure.noActiveTenant,
      );
    } catch (e) {
      throw ClinicalEncounterRepositoryErrorMapper.toException(e);
    }
  }
}
