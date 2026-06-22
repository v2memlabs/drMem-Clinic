import '../../shared/models/app_user.dart';
import '../auth/session_bootstrap.dart';
import 'active_tenant_context_loader.dart';
import 'active_tenant_load_result.dart';

/// Supabase tenant yükleme placeholder — remote çağrı yok (Paket 4+).
class SupabaseActiveTenantContextLoaderStub implements ActiveTenantContextLoader {
  const SupabaseActiveTenantContextLoaderStub();

  @override
  ActiveTenantLoadResult loadFromMockUser(AppUser user) {
    return ActiveTenantLoadResult.failure(ActiveTenantLoadFailure.notSupportedInMockMode);
  }

  @override
  ActiveTenantLoadResult loadFromBootstrap(SessionBootstrapContext context) {
    return ActiveTenantLoadResult.failure(ActiveTenantLoadFailure.backendNotConfigured);
  }
}
