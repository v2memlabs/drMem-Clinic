import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'mock_staff_leave_record_repository.dart';
import 'staff_leave_record_repository.dart';
import 'staff_leave_record_repository_stub.dart';
import 'supabase_staff_leave_record_repository.dart';

abstract final class StaffLeaveRecordRepositoryProvider {
  static StaffLeaveRecordRepository? _cache;

  @visibleForTesting
  static StaffLeaveRecordRepository? testOverride;

  static StaffLeaveRecordRepository get repository {
    if (testOverride != null) return testOverride!;
    _cache ??= _resolve();
    return _cache!;
  }

  static bool get usesRemote =>
      AppBackendConfig.isSupabase &&
      SupabaseEnvConfig.isSupabaseConfigured &&
      SupabaseClientInitializer.isInitialized &&
      AuthSession.isLoggedIn &&
      SessionReadiness.isReady &&
      ActiveTenantContextStore.current != null;

  static StaffLeaveRecordRepository _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: usesRemote,
      mockFactory: () => MockStaffLeaveRecordRepository(),
      remoteFactory: () => SupabaseStaffLeaveRecordRepository.fromSupabase(),
      unavailableFactory: () => const StaffLeaveRecordRepositoryStub(),
    );
  }

  static void resetCache() {
    _cache = null;
  }
}
