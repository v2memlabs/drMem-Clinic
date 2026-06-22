import '../../shared/models/app_user.dart';
import '../data/backend_config.dart';
import '../saas/active_tenant_context.dart';
import 'active_tenant_context_store.dart';
import 'mock_active_tenant_context_loader.dart';

/// Mock giriş sonrası varsayılan demo tenant bağlamını üretir (UI değişmez).
///
/// İçerik [MockActiveTenantContextLoader] ile üretilir; ayarlar senkronu korunur.
abstract final class MockTenantContextBridge {
  static const String demoTenantId = 'tenant-demo-1';

  static final MockActiveTenantContextLoader _loader =
      const MockActiveTenantContextLoader();

  static void bindFromAppUser(AppUser? user) {
    if (!AppBackendConfig.isMock) {
      if (user == null) {
        ActiveTenantContextStore.clearSilently();
      }
      return;
    }

    if (user == null) {
      ActiveTenantContextStore.clearSilently();
      return;
    }

    final result = _loader.loadFromMockUser(user);
    if (result.success && result.context != null) {
      ActiveTenantContextStore.set(result.context);
    } else {
      ActiveTenantContextStore.clear();
    }
  }

  /// Ayarlar ekranından klinik adı güncellenince sidebar ile uyum için tenant adını yeniler.
  static void refreshTenantFromSettings() {
    if (!AppBackendConfig.isMock) return;

    final ctx = ActiveTenantContextStore.current;
    if (ctx == null) return;

    final user = _userFromContext(ctx);
    if (user == null) {
      bindFromAppUser(null);
      return;
    }
    bindFromAppUser(user);
  }

  static AppUser? _userFromContext(ActiveTenantContext ctx) {
    return AppUser(
      id: ctx.profile.userId,
      username: ctx.profile.userId,
      displayName: ctx.profile.displayName,
      role: ctx.membership.role,
    );
  }
}
