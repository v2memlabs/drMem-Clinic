import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_surgery_procedure_note_repository_contract.dart';
import 'mock_async_surgery_procedure_note_repository_adapter.dart';
import 'supabase_async_surgery_procedure_note_repository_stub.dart';
import 'supabase_surgery_procedure_note_repository.dart';
import 'surgery_procedure_note_repository_backend_gate.dart';
import 'surgery_repository.dart';

abstract final class SurgeryProcedureNoteRepositoryProvider {
  static AsyncSurgeryProcedureNoteRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncSurgeryProcedureNoteRepositoryContract? testOverride;

  static SurgeryRepository get instance => SurgeryRepository.instance;

  static AsyncSurgeryProcedureNoteRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemoteSurgeryProcedureNotes =>
      _shouldUseRemoteSurgeryProcedureNotes();

  static AsyncSurgeryProcedureNoteRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemoteSurgeryProcedureNotes(),
      mockFactory: () => MockAsyncSurgeryProcedureNoteRepositoryAdapter(),
      remoteFactory: () => SupabaseSurgeryProcedureNoteRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabaseAsyncSurgeryProcedureNoteRepositoryStub(),
    );
  }

  static bool _shouldUseRemoteSurgeryProcedureNotes() {
    return SurgeryProcedureNoteRepositoryBackendGate
        .shouldUseRemoteSurgeryProcedureNotes(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isSurgeryRoleEligible: AuthSession.canViewSurgeryNotes,
    );
  }

  static void resetCache() {
    _asyncCache = null;
  }
}
