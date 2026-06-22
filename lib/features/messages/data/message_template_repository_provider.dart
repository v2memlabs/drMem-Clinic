import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_message_template_repository_contract.dart';
import 'message_template_repository_backend_gate.dart';
import 'mock_async_message_template_repository_adapter.dart';
import 'supabase_async_message_template_repository_stub.dart';
import 'supabase_message_template_repository.dart';

abstract final class MessageTemplateRepositoryProvider {
  static AsyncMessageTemplateRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncMessageTemplateRepositoryContract? testOverride;

  static AsyncMessageTemplateRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteMessageTemplates =>
      _shouldUseRemoteMessageTemplates();

  static AsyncMessageTemplateRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteMessageTemplates(),
      mockFactory: () => MockAsyncMessageTemplateRepositoryAdapter(),
      remoteFactory: () => SupabaseMessageTemplateRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabaseAsyncMessageTemplateRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteMessageTemplates() {
    return MessageTemplateRepositoryBackendGate.shouldUseRemoteMessageTemplates(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isMessageTemplateRoleEligible:
          AuthSession.canViewMessages || AuthSession.canViewMessageTemplates,
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
