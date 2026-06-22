import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'assistant_clinical_summary_repository.dart';
import 'clinical_role_summary_repository_backend_gate.dart';
import 'physiotherapist_clinical_summary_repository.dart';
import 'mock_assistant_clinical_summary_repository.dart';
import 'mock_physiotherapist_clinical_summary_repository.dart';
import 'supabase_assistant_clinical_summary_repository.dart';
import 'supabase_assistant_clinical_summary_repository_stub.dart';
import 'supabase_physiotherapist_clinical_summary_repository.dart';
import 'supabase_physiotherapist_clinical_summary_repository_stub.dart';

/// Assistant / FTR güvenli klinik özet repository çözümleyici.
///
/// Remote yalnızca allowlist RPC repository'leri seçer — asla
/// [ClinicalEncounterRepository] veya full-table async adapter fallback yok.
abstract final class ClinicalRoleSummaryRepositoryProvider {
  static AssistantClinicalSummaryRepository? _assistantCache;
  static PhysiotherapistClinicalSummaryRepository? _physiotherapistCache;

  @visibleForTesting
  static AssistantClinicalSummaryRepository? assistantTestOverride;

  @visibleForTesting
  static PhysiotherapistClinicalSummaryRepository? physiotherapistTestOverride;

  static AssistantClinicalSummaryRepository get assistantRepository {
    if (assistantTestOverride != null) return assistantTestOverride!;
    _assistantCache ??= _resolveAssistant();
    return _assistantCache!;
  }

  static PhysiotherapistClinicalSummaryRepository get physiotherapistRepository {
    if (physiotherapistTestOverride != null) {
      return physiotherapistTestOverride!;
    }
    _physiotherapistCache ??= _resolvePhysiotherapist();
    return _physiotherapistCache!;
  }

  static bool get usesRemoteAssistantClinicalSummaries =>
      _shouldUseRemoteAssistantClinicalSummaries();

  static bool get usesRemotePhysiotherapistClinicalSummaries =>
      _shouldUseRemotePhysiotherapistClinicalSummaries();

  static AssistantClinicalSummaryRepository _resolveAssistant() {
    if (_shouldUseRemoteAssistantClinicalSummaries()) {
      return SupabaseAssistantClinicalSummaryRepository.fromSupabase();
    }
    if (AppBackendConfig.isMock) {
      return const MockAssistantClinicalSummaryRepository();
    }
    return const SupabaseAssistantClinicalSummaryRepositoryStub();
  }

  static PhysiotherapistClinicalSummaryRepository _resolvePhysiotherapist() {
    if (_shouldUseRemotePhysiotherapistClinicalSummaries()) {
      return SupabasePhysiotherapistClinicalSummaryRepository.fromSupabase();
    }
    if (AppBackendConfig.isMock) {
      return const MockPhysiotherapistClinicalSummaryRepository();
    }
    return const SupabasePhysiotherapistClinicalSummaryRepositoryStub();
  }

  static bool _shouldUseRemoteAssistantClinicalSummaries() {
    return ClinicalRoleSummaryRepositoryBackendGate
        .canUseAssistantClinicalSummaryRemote(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isAssistantSummaryRoleEligible:
          AuthSession.canViewClinicalDiagnosisSummary,
    );
  }

  static bool _shouldUseRemotePhysiotherapistClinicalSummaries() {
    return ClinicalRoleSummaryRepositoryBackendGate
        .canUsePhysiotherapistClinicalSummaryRemote(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isPhysiotherapistSummaryRoleEligible: AuthSession.canViewClinicalSummary,
    );
  }

  /// Provider instance cache sıfırlama — [assistantTestOverride] korunur.
  static void resetCache() {
    _assistantCache = null;
    _physiotherapistCache = null;
  }

  @visibleForTesting
  static void clearTestOverrides() {
    assistantTestOverride = null;
    physiotherapistTestOverride = null;
  }
}
