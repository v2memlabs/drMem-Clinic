import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_surgery_note_template_repository_contract.dart';
import 'mock_async_surgery_note_template_repository_adapter.dart';
import 'supabase_async_surgery_note_template_repository_stub.dart';
import 'supabase_surgery_note_template_repository.dart';
import 'surgery_note_template_repository_backend_gate.dart';

abstract final class SurgeryNoteTemplateRepositoryProvider {
  static AsyncSurgeryNoteTemplateRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncSurgeryNoteTemplateRepositoryContract? testOverride;

  static AsyncSurgeryNoteTemplateRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteSurgeryNoteTemplates =>
      _shouldUseRemoteSurgeryNoteTemplates();

  static AsyncSurgeryNoteTemplateRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteSurgeryNoteTemplates(),
      mockFactory: () => MockAsyncSurgeryNoteTemplateRepositoryAdapter(),
      remoteFactory: () => SupabaseSurgeryNoteTemplateRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabaseAsyncSurgeryNoteTemplateRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteSurgeryNoteTemplates() {
    return SurgeryNoteTemplateRepositoryBackendGate.shouldUseRemoteSurgeryNoteTemplates(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isSurgeryRoleEligible: AuthSession.canEditSurgeryNotes,
    );
  }

  static void resetCache() {
    _asyncCache = null;
  }
}
