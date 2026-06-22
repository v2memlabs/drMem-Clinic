import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_pdf_output_repository_contract.dart';
import 'mock_async_pdf_output_repository_adapter.dart';
import 'pdf_output_repository.dart';
import 'pdf_output_repository_backend_gate.dart';
import 'supabase_async_pdf_output_repository_stub.dart';
import 'supabase_pdf_output_repository.dart';

/// PDF çıktı repository çözümleyici — sync UI mock; async remote hazır.
abstract final class PdfOutputRepositoryProvider {
  static AsyncPdfOutputRepositoryContract? _asyncCache;

  @visibleForTesting
  static AsyncPdfOutputRepositoryContract? testOverride;

  /// Mevcut sync singleton — mock in-memory (legacy UI uyumu).
  static PdfOutputRepository get instance => PdfOutputRepository.instance;

  /// Async PDF çıktı repository — backend + oturum + rol koşullu.
  static AsyncPdfOutputRepositoryContract get asyncRepository {
    if (testOverride != null) return testOverride!;
    _asyncCache ??= _resolveAsync();
    return _asyncCache!;
  }

  static bool get usesRemotePdfOutputs => _shouldUseRemotePdfOutputs();

  static AsyncPdfOutputRepositoryContract _resolveAsync() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemotePdfOutputs(),
      mockFactory: () => MockAsyncPdfOutputRepositoryAdapter(),
      remoteFactory: () => SupabasePdfOutputRepository.fromSupabase(),
      unavailableFactory: () => const SupabaseAsyncPdfOutputRepositoryStub(),
    );
  }

  static bool _shouldUseRemotePdfOutputs() {
    return PdfOutputRepositoryBackendGate.shouldUseRemotePdfOutputs(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isPdfOutputRoleEligible: AuthSession.canViewPdfOutputs,
    );
  }

  static void resetCache() {
    _asyncCache = null;
  }
}
