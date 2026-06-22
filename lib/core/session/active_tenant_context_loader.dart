import '../../shared/models/app_user.dart';
import '../auth/session_bootstrap.dart';
import 'active_tenant_load_result.dart';

/// Mock veya Supabase kaynağından [ActiveTenantContext] üretir.
abstract interface class ActiveTenantContextLoader {
  /// Demo giriş — ayarlardaki klinik adı/branş ile sentetik tenant.
  ActiveTenantLoadResult loadFromMockUser(AppUser user);

  /// Bootstrap bağlamından tenant + membership (Supabase yolu).
  ActiveTenantLoadResult loadFromBootstrap(SessionBootstrapContext context);
}
