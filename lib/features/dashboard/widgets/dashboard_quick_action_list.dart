import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_route_permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class DashboardQuickAction {
  final IconData icon;
  final String label;
  final String route;

  const DashboardQuickAction({
    required this.icon,
    required this.label,
    required this.route,
  });
}

/// Gölgesiz hızlı işlem listesi — maksimum 5 aksiyon (çağıran filtreler).
class DashboardQuickActionList extends StatelessWidget {
  final List<DashboardQuickAction> actions;

  const DashboardQuickActionList({
    super.key,
    required this.actions,
  });

  static List<DashboardQuickAction> filterAllowed(
    List<DashboardQuickAction> source, {
    int max = 5,
  }) {
    // Sıra önemlidir; max sınırı listenin son elemanlarını keser.
    final allowed = source
        .where((a) => AuthRoutePermissions.canAccessPath(a.route))
        .take(max)
        .toList();
    return allowed;
  }

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Material(
      color: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Icon(
                actions[i].icon,
                size: 22,
                color: AppColors.textSecondary,
              ),
              title: Text(
                actions[i].label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              onTap: () => context.go(actions[i].route),
            ),
          ],
        ],
      ),
    );
  }
}
