import 'package:flutter/material.dart';

import '../../core/auth/auth_route_permissions.dart';

/// Dashboard kartı — route [AuthRoutePermissions] ile filtrelenir.
class DashboardNavItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color accent;

  const DashboardNavItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.accent,
  });
}

List<DashboardNavItem> filterDashboardNavItems(List<DashboardNavItem> items) {
  return items
      .where((item) => AuthRoutePermissions.canAccessPath(item.route))
      .toList();
}
