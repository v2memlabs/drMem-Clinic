import '../../../core/data/repository_cache_coordinator.dart';
import '../../../core/data/remote_list_refresh_coordinator.dart';
import '../../../core/session/session_auto_lock_controller.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../../../core/tenant/tenant_role_access_gate.dart';
import '../../lab_orders/data/lab_order_catalog_gate.dart';
import '../models/tenant_preferences.dart';
import '../models/user_display_preferences.dart';
import 'profile_settings_repository_provider.dart';
import 'tenant_settings_repository_provider.dart';

/// Oturum açılışında tenant tercihlerini uzak kaynaktan senkronlar.
abstract final class SettingsPersistenceSync {
  static Future<void> syncAfterSessionEstablished() async {
    final repo = TenantSettingsRepositoryProvider.repository;

    if (TenantSettingsRepositoryProvider.usesRemote) {
      try {
        final preferences = await repo.loadPreferences();
        await _applyDisplayPreferences(preferences);
      } catch (_) {
        await _applyDisplayPreferences(TenantPreferences.defaults);
      }
    } else {
      await _applyDisplayPreferences(TenantPreferences.defaults);
    }

    try {
      final security = await repo.loadSecuritySettings();
      await appSettingsController.applyTenantSecuritySettings(security);
      sessionAutoLockController.configure(security.autoLockDuration);
    } catch (_) {
      sessionAutoLockController.configure(
        appSettingsController.settings.autoLockDuration,
      );
    }

    try {
      final financial = await repo.loadFinancialFeatureSettings();
      TenantFinancialFeatureGate.apply(financial);
    } catch (_) {
      TenantFinancialFeatureGate.reset();
    }

    try {
      final labCatalog = await repo.loadLabOrderCatalogSettings();
      LabOrderCatalogGate.apply(labCatalog);
    } catch (_) {
      LabOrderCatalogGate.reset();
    }

    try {
      final roleAccess = await repo.loadRoleAccessSettings();
      TenantRoleAccessGate.apply(roleAccess);
    } catch (_) {
      TenantRoleAccessGate.reset();
    }

    // Rol/finans matrisi yüklendikten sonra stub cache'lenmiş repo'ları yenile.
    RepositoryCacheCoordinator.resetAllRemoteProviderCaches();
    RemoteListRefreshCoordinator.markAllStale();

    sessionAutoLockController.arm();
  }

  static Future<void> _applyDisplayPreferences(
    TenantPreferences tenantPreferences,
  ) async {
    UserDisplayPreferences? userPreferences;
    try {
      userPreferences = await ProfileSettingsRepositoryProvider.repository
          .loadMyDisplayPreferences();
    } catch (_) {
      // Profil kaynağı yoksa tenant varsayılanı kullanılır.
    }

    final effective = userPreferences ??
        UserDisplayPreferences.fromTenant(tenantPreferences);
    await appSettingsController.applyUserDisplayPreferences(effective);
  }

  /// Oturum kapatma / cold-start purge — tenant oturum kapsamı sıfırlanır.
  static void clearSessionScoped() {
    sessionAutoLockController.disarm();
    sessionAutoLockController.configure(
      appSettingsController.settings.autoLockDuration,
    );
    TenantFinancialFeatureGate.reset();
    LabOrderCatalogGate.reset();
    TenantRoleAccessGate.reset();
  }
}
