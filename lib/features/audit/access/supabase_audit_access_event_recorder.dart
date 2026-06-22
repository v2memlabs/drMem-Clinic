import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import 'audit_access_event.dart';
import 'audit_access_event_recorder.dart';
import 'audit_access_metadata_sanitizer.dart';

/// Supabase — `record_audit_access_event` RPC (SECURITY DEFINER, append-only).
final class SupabaseAuditAccessEventRecorder implements AuditAccessEventRecorder {
  SupabaseAuditAccessEventRecorder(this._client);

  factory SupabaseAuditAccessEventRecorder.fromSupabase() {
    return SupabaseAuditAccessEventRecorder(Supabase.instance.client);
  }

  static const String rpcName = 'record_audit_access_event';

  final SupabaseClient _client;

  @override
  Future<void> record(AuditAccessEvent event) async {
    if (!AppBackendConfig.isSupabase || !SupabaseEnvConfig.isSupabaseConfigured) {
      return;
    }
    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.isEmpty) return;

    final meta = AuditAccessMetadataSanitizer.sanitize({
      ...event.metadata,
      ...AuditAccessMetadataSanitizer.buildBase(
        success: event.success,
        failureCategory: event.failureCategory,
        source: event.source,
        actorRole: ActiveTenantContextStore.current?.role,
        actorUserId: ActiveTenantContextStore.current?.userId,
        tenantId: tenantId,
      ),
    });

    String? recordUuid;
    final encounterId = event.encounterId;
    if (encounterId != null && encounterId.trim().isNotEmpty) {
      recordUuid = encounterId.trim();
    } else {
      final appointmentId = event.appointmentId;
      if (appointmentId != null && appointmentId.trim().isNotEmpty) {
        recordUuid = appointmentId.trim();
      } else {
        final fileId = event.fileId;
        if (fileId != null && fileId.trim().isNotEmpty) {
          recordUuid = fileId.trim();
        }
      }
    }

    try {
      await _client.rpc(
        rpcName,
        params: {
          'p_action': event.eventType,
          'p_module': event.eventScope,
          if (recordUuid != null) 'p_record_id': recordUuid,
          if (event.patientId != null && event.patientId!.trim().isNotEmpty)
            'p_patient_id': event.patientId!.trim(),
          'p_metadata': meta,
          'p_success': event.success,
          if (event.failureCategory != null)
            'p_failure_category': event.failureCategory,
        },
      );
    } catch (_) {
      // Audit failure must not break clinical read path.
    }
  }
}
