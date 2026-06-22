import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../layout/app_breakpoints.dart';
import '../layout/responsive_layout.dart';

/// Dashboard bölüm başlığı + içerik.
class DashboardSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const DashboardSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDeepTeal,
                    ),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

/// Dashboard içerik alanı — geniş ekranda max genişlik.
class DashboardPageBody extends StatelessWidget {
  final Widget child;

  const DashboardPageBody({super.key, required this.child});

  static const double maxContentWidth = AppBreakpoints.dashboardMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = ResponsiveLayout.cappedWidth(
          constraints.maxWidth,
          maxContentWidth,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cap),
            child: child,
          ),
        );
      },
    );
  }
}
