import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/premium_surface.dart';
import 'settings_categories.dart';

class SettingsCategoryCard extends StatelessWidget {
  final SettingsCategoryDef category;

  const SettingsCategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(category.routePath),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: PremiumSurface.card(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(category.icon, size: 20, color: AppColors.navy),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: muted, size: 20),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  category.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  category.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
