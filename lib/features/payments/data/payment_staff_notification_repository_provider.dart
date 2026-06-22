import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/config/supabase_client_initializer.dart';
import '../../../core/config/supabase_env_config.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/data/backend_config.dart';
import '../../../core/data/remote_repository_resolver.dart';
import '../../../core/session/active_tenant_context_store.dart';
import '../../../core/session/session_readiness.dart';
import 'async_payment_staff_notification_repository_contract.dart';
import 'mock_async_payment_staff_notification_repository_adapter.dart';
import 'payment_staff_notification_repository_backend_gate.dart';
import 'supabase_payment_staff_notification_repository.dart';
import 'supabase_payment_staff_notification_repository_stub.dart';

abstract final class PaymentStaffNotificationRepositoryProvider {
  static AsyncPaymentStaffNotificationRepositoryContract? _cache;

  @visibleForTesting
  static AsyncPaymentStaffNotificationRepositoryContract? testOverride;

  static AsyncPaymentStaffNotificationRepositoryContract get repository {
    if (testOverride != null) return testOverride!;
    _cache ??= _resolve();
    return _cache!;
  }

  static bool get usesRemotePaymentStaffNotifications =>
      _shouldUseRemotePaymentStaffNotifications();

  static AsyncPaymentStaffNotificationRepositoryContract _resolve() {
    return RemoteRepositoryResolver.resolve(
      remoteReady: _shouldUseRemotePaymentStaffNotifications(),
      mockFactory: () => MockAsyncPaymentStaffNotificationRepositoryAdapter(),
      remoteFactory: () =>
          SupabasePaymentStaffNotificationRepository.fromSupabase(),
      unavailableFactory: () =>
          const SupabasePaymentStaffNotificationRepositoryStub(),
    );
  }

  static bool _shouldUseRemotePaymentStaffNotifications() {
    final role = AuthSession.currentUser?.role;
    return PaymentStaffNotificationRepositoryBackendGate
        .shouldUseRemotePaymentStaffNotifications(
      isMockBackend: AppBackendConfig.isMock,
      isSupabaseConfigured: SupabaseEnvConfig.isSupabaseConfigured,
      isSupabaseInitialized: SupabaseClientInitializer.isInitialized,
      isLoggedIn: AuthSession.isLoggedIn,
      isSessionReady: SessionReadiness.isReady,
      hasActiveTenant: ActiveTenantContextStore.current != null,
      isPaymentRoleEligible:
          AuthSession.canViewPayments || AuthSession.canEditPayments,
      isAssistantRole: role == AppRoles.assistant,
    );
  }

  static void resetCache() => _cache = null;

  @visibleForTesting
  static void clearTestOverrides() => testOverride = null;
}
