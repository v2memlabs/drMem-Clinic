import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'premium_surface.dart';

/// Detay ekranı üst özet kartı.
class DetailHeaderCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> chips;
  final List<Widget> actions;

  const DetailHeaderCard({
    super.key,
    required this.title,
    this.subtitle,
    this.chips = const [],
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: PremiumSurface.card(elevated: true),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDeepTeal,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (chips.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xxs,
                runSpacing: AppSpacing.xxs,
                children: chips,
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
