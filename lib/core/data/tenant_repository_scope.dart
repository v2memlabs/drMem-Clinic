import 'backend_config.dart';
import '../session/active_tenant_context_store.dart';
import '../session/mock_tenant_context_bridge.dart';

/// Repository katmanında ileride tenant filtresi için aktif tenant kimliği.
///
/// Mock modda tek demo tenant; UI'dan parametre geçirilmez.
abstract final class TenantRepositoryScope {
  /// Aktif tenant yoksa demo tenant fallback (mock oturum).
  static String get activeTenantId =>
      ActiveTenantContextStore.current?.tenantId ??
      MockTenantContextBridge.demoTenantId;

  /// Oturum tenant bağlamı yüklü mü (remote sorgu öncesi kontrol).
  static bool get hasActiveTenant =>
      ActiveTenantContextStore.current != null || AppBackendConfig.isMock;

  /// İleride remote listeleme: `WHERE tenant_id = activeTenantId`.
  static String get scopeLabel => AppBackendConfig.isMock
      ? 'mock:$activeTenantId'
      : 'remote:$activeTenantId';
}
