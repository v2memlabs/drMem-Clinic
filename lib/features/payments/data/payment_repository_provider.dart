import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_payment_repository_contract.dart';
import 'mock_async_payment_repository_adapter.dart';
import 'payment_repository.dart';
import 'payment_repository_backend_gate.dart';
import 'supabase_payment_repository.dart';
import 'supabase_payment_repository_stub.dart';

/// Ödeme repository çözümleyici — sync UI mock; async active backend.
abstract final class PaymentRepositoryProvider {
  static AsyncPaymentRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncPaymentRepositoryContract? testOverride;

  static PaymentRepository get instance => PaymentRepository.instance;

  static AsyncPaymentRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemotePayments => _shouldUseRemotePayments();

  static AsyncPaymentRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemotePayments(),
      mockFactory: () => MockAsyncPaymentRepositoryAdapter(),
      remoteFactory: () => SupabasePaymentRepository.fromSupabase(),
      unavailableFactory: () => const SupabasePaymentRepositoryStub(),
    );
  }

  static bool _shouldUseRemotePayments() {
    return PaymentRepositoryBackendGate.shouldUseRemotePayments(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isPaymentRoleEligible:
          AuthSession.canViewPayments || AuthSession.canEditPayments,
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
