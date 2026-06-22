import '../data/backend_config.dart';
import 'active_tenant_context_loader.dart';
import 'mock_active_tenant_context_loader.dart';
import 'supabase_active_tenant_context_loader.dart';

/// Backend moduna göre aktif tenant loader.
abstract final class SessionContextResolver {
  static ActiveTenantContextLoader get tenantLoader => _resolveLoader();

  static ActiveTenantContextLoader _resolveLoader() {
    if (AppBackendConfig.isMock) {
      return const MockActiveTenantContextLoader();
    }
    return const SupabaseActiveTenantContextLoader();
  }
}
