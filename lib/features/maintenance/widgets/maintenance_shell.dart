import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_env_config.dart';
import '../../../core/theme/app_spacing.dart';

/// Bakım konsolu kabuğu — normal AppShell/sidebar yok; yalnız bakım navigasyonu.
class MaintenanceShell extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const MaintenanceShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  static const _destinations = <_MaintenanceNavItem>[
    _MaintenanceNavItem(
      label: 'Dashboard',
      path: '/maintenance',
      icon: Icons.dashboard_outlined,
    ),
    _MaintenanceNavItem(
      label: 'Tanı',
      path: '/maintenance/diagnostics',
      icon: Icons.medical_information_outlined,
    ),
    _MaintenanceNavItem(
      label: 'Auth / Profil',
      path: '/maintenance/auth-profile',
      icon: Icons.manage_accounts_outlined,
    ),
    _MaintenanceNavItem(
      label: 'Klinikler',
      path: '/maintenance/tenants',
      icon: Icons.business_outlined,
    ),
    _MaintenanceNavItem(
      label: 'Yeni Klinik',
      path: '/maintenance/tenants/new',
      icon: Icons.add_business_outlined,
    ),
    _MaintenanceNavItem(
      label: 'İlk Yönetici',
      path: '/maintenance/bootstrap/new',
      icon: Icons.person_add_outlined,
    ),
    _MaintenanceNavItem(
      label: 'Üyelikler',
      path: '/maintenance/memberships',
      icon: Icons.group_outlined,
    ),
  ];

  int _selectedIndex(String path) {
    if (path == '/maintenance') return 0;
    for (var i = 0; i < _destinations.length; i++) {
      final item = _destinations[i];
      if (path == item.path || path.startsWith('${item.path}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).matchedLocation;
    final selected = _selectedIndex(path);
    final envLabel = AppEnvConfig.isStaging
        ? 'STAGING'
        : AppEnvConfig.isDev
            ? 'DEV'
            : 'ORTAM';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Chip(
              label: Text(envLabel),
              visualDensity: VisualDensity.compact,
            ),
          ),
          ...?actions,
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: selected,
        onDestinationSelected: (index) {
          final dest = _destinations[index];
          if (dest.path != path) {
            Navigator.of(context).pop();
            context.go(dest.path);
          } else {
            Navigator.of(context).pop();
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'Bakım Konsolu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ..._destinations.map(
            (d) => NavigationDrawerDestination(
              icon: Icon(d.icon),
              label: Text(d.label),
            ),
          ),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}

class _MaintenanceNavItem {
  final String label;
  final String path;
  final IconData icon;

  const _MaintenanceNavItem({
    required this.label,
    required this.path,
    required this.icon,
  });
}
