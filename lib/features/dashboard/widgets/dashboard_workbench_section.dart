import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Workbench bölüm başlığı — düz metin, accent yok.
class DashboardWorkbenchSection extends StatelessWidget {
  final String title;
  final Widget child;

  const DashboardWorkbenchSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
