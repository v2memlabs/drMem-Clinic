import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'premium_surface.dart';

/// Liste veya detay ekranlarında boş sonuç gösterimi.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: AppRadius.cardBorder,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppShadows.subtle,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PremiumSurface.iconBadge(
                    icon: icon,
                    size: 48,
                    accent: AppColors.accentTurquoise,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDeepTeal,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (action != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
