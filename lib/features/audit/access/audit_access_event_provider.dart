import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import 'audit_access_event_recorder.dart';
import 'mock_audit_access_event_recorder.dart';
import 'no_op_audit_access_event_recorder.dart';
import 'supabase_audit_access_event_recorder.dart';

/// Audit access recorder çözümleyici.
abstract final class AuditAccessEventProvider {
  static AuditAccessEventRecorder get recorder {
    if (AppBackendConfig.isMock) {
      return MockAuditAccessEventRecorder.instance;
    }
    if (AppBackendConfig.isSupabase && SupabaseEnvConfig.isSupabaseConfigured) {
      return SupabaseAuditAccessEventRecorder.fromSupabase();
    }
    return NoOpAuditAccessEventRecorder.instance;
  }
}
