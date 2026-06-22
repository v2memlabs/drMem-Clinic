import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/assistant_clinical_summary.dart';
import 'assistant_clinical_summary_mapper.dart';
import 'assistant_clinical_summary_repository.dart';
import 'assistant_clinical_summary_repository_error_mapper.dart';
import 'assistant_clinical_summary_repository_failure.dart';
import 'clinical_summary_rpc_response_parser.dart';

/// Assistant güvenli özet — yalnızca allowlist RPC (full `clinical_encounters` yok).
///
/// [AsyncClinicalEncounterRepositoryContract] ile değiştirilmez.
class SupabaseAssistantClinicalSummaryRepository
    implements AssistantClinicalSummaryRepository {
  SupabaseAssistantClinicalSummaryRepository(this._client);

  factory SupabaseAssistantClinicalSummaryRepository.fromSupabase() {
    return SupabaseAssistantClinicalSummaryRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  @visibleForTesting
  static const String listRpcName = 'list_assistant_clinical_summaries';

  @visibleForTesting
  static const String getRpcName = 'get_assistant_clinical_summary';

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const AssistantClinicalSummaryRepositoryException(
        AssistantClinicalSummaryRepositoryFailure.notConfigured,
      );
    }
  }

  void _requireActiveTenantSession() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const AssistantClinicalSummaryRepositoryException(
        AssistantClinicalSummaryRepositoryFailure.noActiveTenant,
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AssistantClinicalSummaryRepositoryException {
      rethrow;
    } catch (e) {
      throw AssistantClinicalSummaryRepositoryErrorMapper.toException(e);
    }
  }

  @visibleForTesting
  static Map<String, dynamic> listRpcParams({String? patientId}) {
    final trimmed = patientId?.trim() ?? '';
    if (trimmed.isEmpty) return const {};
    return {'p_patient_id': trimmed};
  }

  @visibleForTesting
  static Map<String, dynamic> getRpcParams(String encounterId) {
    return {'p_encounter_id': encounterId.trim()};
  }

  List<AssistantClinicalSummary> _mapRows(List<Map<String, dynamic>> rows) {
    return rows.map(_mapRow).toList();
  }

  AssistantClinicalSummary _mapRow(Map<String, dynamic> row) {
    try {
      return AssistantClinicalSummaryMapper.fromMap(row);
    } on AssistantClinicalSummaryRepositoryException {
      rethrow;
    } catch (_) {
      throw const AssistantClinicalSummaryRepositoryException(
        AssistantClinicalSummaryRepositoryFailure.invalidRow,
      );
    }
  }

  @override
  Future<List<AssistantClinicalSummary>> listAssistantClinicalSummaries({
    String? patientId,
  }) async {
    return _guard(() async {
      _requireActiveTenantSession();

      final response = await _client.rpc(
        listRpcName,
        params: listRpcParams(patientId: patientId),
      );

      final rows = ClinicalSummaryRpcResponseParser.coerceRowList(response);
      return _mapRows(rows);
    });
  }

  @override
  Future<AssistantClinicalSummary?> getAssistantClinicalSummary(
    String encounterId,
  ) async {
    if (encounterId.trim().isEmpty) return null;

    return _guard(() async {
      _requireActiveTenantSession();

      final response = await _client.rpc(
        getRpcName,
        params: getRpcParams(encounterId),
      );

      final row = ClinicalSummaryRpcResponseParser.coerceSingleRow(response);
      if (row == null) return null;
      return _mapRow(row);
    });
  }
}
