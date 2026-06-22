import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Kartsız form bölümü — detay [FlatDetailSection] ile aynı başlık/divider dili.
class FlatFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool showBottomDivider;
  final double fieldGap;

  const FlatFormSection({
    super.key,
    required this.title,
    required this.children,
    this.showBottomDivider = true,
    this.fieldGap = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDeepTeal,
                ),
          ),
        ),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: fieldGap),
          children[i],
        ],
        if (showBottomDivider)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
          ),
      ],
    );
  }
}
