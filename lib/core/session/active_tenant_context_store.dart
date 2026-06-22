import 'dart:async';

import '../data/repository_cache_coordinator.dart';
import '../saas/active_tenant_context.dart';
import 'active_tenant_context_sync.dart';

/// Aktif tenant bağlamı — mock oturumla senkron; remote auth sonraki faz.
abstract final class ActiveTenantContextStore {
  static ActiveTenantContext? current;

  static void set(ActiveTenantContext? context) {
    final previousTenantId = current?.tenantId;
    final nextTenantId = context?.tenantId;
    current = context;
    if (previousTenantId != nextTenantId) {
      RepositoryCacheCoordinator.onActiveTenantChanged();
      if (nextTenantId != null && nextTenantId.isNotEmpty) {
        unawaited(ActiveTenantContextSync.syncBestEffort());
      }
    }
  }

  /// Oturum kapatma — cache coordinator çağırmadan (üst katman zaten sıfırlar).
  static void clearSilently() {
    current = null;
  }

  static void clear() {
    if (current == null) return;
    clearSilently();
    RepositoryCacheCoordinator.onActiveTenantChanged();
  }
}
