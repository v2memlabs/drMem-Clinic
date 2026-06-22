import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Ana ekran başlığında tarih/saat solunda kırmızı uyarı butonu.
class DashboardNotificationAlertButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const DashboardNotificationAlertButton({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            borderRadius: AppRadius.mediumBorder,
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 18,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
