import '../saas/active_tenant_context.dart';
import '../saas/user_profile.dart';
import 'active_tenant_context_store.dart';

/// Ayar kaydı sonrası bellek içi tenant/profil bağlamını günceller (tenant id değişmez).
abstract final class ActiveTenantContextRefresher {
  static void refreshProfileDisplayName(String displayName) {
    final ctx = ActiveTenantContextStore.current;
    if (ctx == null) return;

    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: ctx.tenant,
        membership: ctx.membership,
        profile: UserProfile(
          userId: ctx.profile.userId,
          displayName: displayName.trim(),
        ),
      ),
    );
  }

  static void refreshTenantBasicInfo({
    required String name,
    required String specialty,
    String? timezone,
  }) {
    final ctx = ActiveTenantContextStore.current;
    if (ctx == null) return;

    ActiveTenantContextStore.set(
      ActiveTenantContext(
        tenant: ctx.tenant.copyWith(
          name: name.trim(),
          specialty: specialty.trim(),
        ),
        membership: ctx.membership,
        profile: ctx.profile,
      ),
    );
  }
}
