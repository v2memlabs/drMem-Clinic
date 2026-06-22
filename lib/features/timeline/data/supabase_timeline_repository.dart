import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../clinical_encounter/data/clinical_summary_rpc_response_parser.dart';
import '../models/timeline_event.dart';
import 'timeline_event_dto.dart';
import 'timeline_event_mapper.dart';
import 'timeline_repository.dart';
import 'timeline_repository_error_mapper.dart';
import 'timeline_repository_failure.dart';

/// Supabase timeline — yalnızca `list_patient_timeline_events` RPC.
///
/// Do not query `clinical_encounters`, `patients`, `appointments`, or
/// `patient_files` directly. No client-side multi-source merge. No audit events.
class SupabaseTimelineRepository implements TimelineRepository {
  SupabaseTimelineRepository(this._client);

  factory SupabaseTimelineRepository.fromSupabase() {
    return SupabaseTimelineRepository(Supabase.instance.client);
  }

  final SupabaseClient _client;

  @visibleForTesting
  static const String listRpcName = 'list_patient_timeline_events';

  void _ensureConfigured() {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      throw const TimelineRepositoryException(
        TimelineRepositoryFailure.notConfigured,
      );
    }
  }

  void _requireActiveTenantSession() {
    _ensureConfigured();
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw const TimelineRepositoryException(
        TimelineRepositoryFailure.noActiveTenant,
      );
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TimelineRepositoryException {
      rethrow;
    } catch (e) {
      throw TimelineRepositoryErrorMapper.toException(e);
    }
  }

  @visibleForTesting
  static Map<String, dynamic> listRpcParams({required String patientId}) {
    return {'p_patient_id': patientId.trim()};
  }

  List<TimelineEvent> _mapRows(List<Map<String, dynamic>> rows) {
    return rows.map(_mapRow).toList();
  }

  TimelineEvent _mapRow(Map<String, dynamic> row) {
    try {
      return TimelineEventMapper.fromDto(TimelineEventDto.fromRpcRow(row));
    } on TimelineRepositoryException {
      rethrow;
    } catch (_) {
      throw const TimelineRepositoryException(
        TimelineRepositoryFailure.invalidRow,
      );
    }
  }

  @override
  Future<List<TimelineEvent>> listPatientTimelineEvents({
    required String patientId,
  }) async {
    final pid = patientId.trim();
    if (pid.isEmpty) {
      throw const TimelineRepositoryException(
        TimelineRepositoryFailure.invalidInput,
      );
    }

    return _guard(() async {
      _requireActiveTenantSession();

      final response = await _client.rpc(
        listRpcName,
        params: listRpcParams(patientId: pid),
      );

      final rows = ClinicalSummaryRpcResponseParser.coerceRowList(response);
      return _mapRows(rows);
    });
  }
}
