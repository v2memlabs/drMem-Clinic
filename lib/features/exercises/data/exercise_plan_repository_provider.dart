import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_exercise_plan_repository_contract.dart';
import 'exercise_plan_repository.dart';
import 'exercise_plan_repository_backend_gate.dart';
import 'mock_async_exercise_plan_repository_adapter.dart';
import 'supabase_async_exercise_plan_repository_stub.dart';
import 'supabase_exercise_plan_repository.dart';

abstract final class ExercisePlanRepositoryProvider {
  static AsyncExercisePlanRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncExercisePlanRepositoryContract? testOverride;

  static ExercisePlanRepository get instance => ExercisePlanRepository.instance;

  static AsyncExercisePlanRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteExercisePlans => _shouldUseRemoteExercisePlans();

  static AsyncExercisePlanRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteExercisePlans(),
      mockFactory: () => MockAsyncExercisePlanRepositoryAdapter(),
      remoteFactory: () => SupabaseExercisePlanRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncExercisePlanRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteExercisePlans() {
    return ExercisePlanRepositoryBackendGate.shouldUseRemoteExercisePlans(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isExercisePlanRoleEligible:
          AuthSession.canViewExercisePlans || AuthSession.canEditExercisePlans,
    );
  }

  static void resetCache() {
    _asyncCache = null;
  }

  @visibleForTesting
  static void clearTestOverrides() {
    testOverride = null;
  }
}
