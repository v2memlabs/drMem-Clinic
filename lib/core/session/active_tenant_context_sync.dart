import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_client_initializer.dart';
import '../config/supabase_env_config.dart';
import '../data/backend_config.dart';
import 'active_tenant_context_store.dart';

/// Aktif tenant RPC senkronu başarısız — RLS yazma reddi riski.
class ActiveTenantContextSyncException implements Exception {
  const ActiveTenantContextSyncException([this.cause]);

  final Object? cause;

  @override
  String toString() =>
      'ActiveTenantContextSyncException${cause != null ? ': $cause' : ''}';
}

/// Uygulama aktif tenant seçimini Supabase RLS ile hizalar.
abstract final class ActiveTenantContextSync {
  /// Yazma işlemlerinden hemen önce çağrılır — RLS `current_tenant_id()` hizası.
  static Future<void> ensureSyncedBeforeWrite() async {
    await syncActiveTenantToDatabase();
  }

  /// Oturum açılışında — hata yutulur (yazma öncesi [ensureSyncedBeforeWrite] kullanın).
  static Future<void> syncBestEffort() async {
    try {
      await syncActiveTenantToDatabase();
    } on ActiveTenantContextSyncException {
      // Login/tenant switch: bir sonraki yazma öncesi tekrar denenecek.
    }
  }

  static Future<void> syncActiveTenantToDatabase() async {
    if (!AppBackendConfig.isSupabase ||
        !SupabaseEnvConfig.isSupabaseConfigured ||
        !SupabaseClientInitializer.isInitialized) {
      return;
    }

    final tenantId = ActiveTenantContextStore.current?.tenantId;
    if (tenantId == null || tenantId.trim().isEmpty) return;

    try {
      await Supabase.instance.client.rpc(
        'set_active_tenant_context',
        params: {'p_tenant_id': tenantId.trim()},
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('ActiveTenantContextSync failed for tenant=$tenantId');
        debugPrint('$e');
        debugPrint('$stackTrace');
      }
      throw ActiveTenantContextSyncException(e);
    }
  }
}
