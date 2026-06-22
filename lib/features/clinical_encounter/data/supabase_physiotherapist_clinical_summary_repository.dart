import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../models/physiotherapist_clinical_summary.dart';
import 'clinical_summary_rpc_response_parser.dart';
import 'physiotherapist_clinical_summary_mapper.dart';
import 'physiotherapist_clinical_summary_repository.dart';
import 'physiotherapist_clinical_summary_repository_error_mapper.dart';
import 'physiotherapist_clinical_summary_repository_failure.dart';

/// Physiotherapist güvenli özet — yalnızca allowlist RPC (full `clinical_encounters` yok).
///
/// [AsyncClinicalEncounterRepositoryContract] ile değiştirilmez.
class SupabasePhysiotherapistClinicalSummaryRepository
    implements PhysiotherapistClinicalSummaryRepository {
  SupabasePhysiotherapistClinicalSummaryRepository(this._client);

  factory SupabasePhysiotherapistClinicalSummaryRepository.fromSupabase() {
    return SupabasePhysiotherapistClinicalSummaryRepository(
      Supabase.instance.client,
    );
  }

  final SupabaseClient _client;

  @visibleForTesting
  static const String listRpcName = 'list_physiotherapist_clinical_summaries';

  @visibleForTesting
  static const String getRpcName = 'get_physiotherapist_clinical_summary';

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const PhysiotherapistClinicalSummaryRepositoryException(
        PhysiotherapistClinicalSummaryRepositoryFailure.notConfigured,
      );
    }
  }

  void _requireActiveTenantSession() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PhysiotherapistClinicalSummaryRepositoryException(
        PhysiotherapistClinicalSummaryRepositoryFailure.noActiveTenant,
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PhysiotherapistClinicalSummaryRepositoryException {
      rethrow;
    } catch (e) {
      throw PhysiotherapistClinicalSummaryRepositoryErrorMapper.toException(e);
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

  List<PhysiotherapistClinicalSummary> _mapRows(List<Map<String, dynamic>> rows) {
    return rows.map(_mapRow).toList();
  }

  PhysiotherapistClinicalSummary _mapRow(Map<String, dynamic> row) {
    try {
      return PhysiotherapistClinicalSummaryMapper.fromMap(row);
    } on PhysiotherapistClinicalSummaryRepositoryException {
      rethrow;
    } catch (_) {
      throw const PhysiotherapistClinicalSummaryRepositoryException(
        PhysiotherapistClinicalSummaryRepositoryFailure.invalidRow,
      );
    }
  }

  @override
  Future<List<PhysiotherapistClinicalSummary>> listPhysiotherapistClinicalSummaries({
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
  Future<PhysiotherapistClinicalSummary?> getPhysiotherapistClinicalSummary(
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
