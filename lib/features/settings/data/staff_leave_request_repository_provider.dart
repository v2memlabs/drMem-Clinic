import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import '../models/staff_leave_request.dart';
import 'mock_staff_leave_request_repository.dart';
import 'staff_leave_request_repository.dart';
import 'supabase_staff_leave_request_repository.dart';

class StaffLeaveRequestRepositoryUnavailable
    implements StaffLeaveRequestRepository {
  const StaffLeaveRequestRepositoryUnavailable();

  Never _fail() => throw const StaffLeaveRequestRepositoryException(
        'İzin talepleri şu anda kullanıma hazır değil.',
      );

  @override
  Future<void> approve(String requestId) async => _fail();

  @override
  Future<int> countPending() async => _fail();

  @override
  Future<StaffLeaveRequest> create(draft) async => _fail();

  @override
  Future<List<StaffLeaveRequest>> listMine() async => _fail();

  @override
  Future<List<StaffLeaveRequest>> listPending() async => _fail();

  @override
  Future<void> reject(String requestId, {String? reason}) async => _fail();
}

abstract final class StaffLeaveRequestRepositoryProvider {
  static StaffLeaveRequestRepository? _cache;

  @visibleForTesting
  static StaffLeaveRequestRepository? testOverride;

  static StaffLeaveRequestRepository get repository {
    if (testOverride != null) return testOverride!;
    final ready = usesRemote;
    if (_cache == null) {
      _cache = _resolve();
      return _cache!;
    }
    if (ready && _cache is StaffLeaveRequestRepositoryUnavailable) {
      _cache = _resolve();
    } else if (!ready &&
        AppBackendConfig.isSupabase &&
        _cache is! MockStaffLeaveRequestRepository &&
        _cache is! StaffLeaveRequestRepositoryUnavailable) {
      _cache = _resolve();
    }
    return _cache!;
  }

  static bool get usesRemote =>
      AppBackendConfig.isSupabase &&
      SupabaseEnvConfig.isSupabaseConfigured &&
      SupabaseClientInitializer.isInitialized &&
      AuthSession.isLoggedIn &&
      SessionReadiness.isReady &&
      ActiveTenantContextStore.current != null;

  static StaffLeaveRequestRepository _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: usesRemote,
      mockFactory: () => MockStaffLeaveRequestRepository(),
      remoteFactory: () => SupabaseStaffLeaveRequestRepository.fromSupabase(),
      unavailableFactory: () => const StaffLeaveRequestRepositoryUnavailable(),
    );
  }

  static void resetCache() {
    _cache = null;
  }
}
