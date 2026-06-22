import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_sent_message_repository_contract.dart';
import 'mock_async_sent_message_repository_adapter.dart';
import 'sent_message_repository_backend_gate.dart';
import 'supabase_async_sent_message_repository_stub.dart';
import 'supabase_sent_message_repository.dart';

abstract final class SentMessageRepositoryProvider {
  static AsyncSentMessageRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncSentMessageRepositoryContract? testOverride;

  static AsyncSentMessageRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteSentMessages => _shouldUseRemoteSentMessages();

  static AsyncSentMessageRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteSentMessages(),
      mockFactory: () => MockAsyncSentMessageRepositoryAdapter(),
      remoteFactory: () => SupabaseSentMessageRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncSentMessageRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteSentMessages() {
    return SentMessageRepositoryBackendGate.shouldUseRemoteSentMessages(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isSentMessageRoleEligible: AuthSession.canViewMessages,
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
