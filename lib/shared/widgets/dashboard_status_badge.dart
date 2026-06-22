import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Dashboard kartlarında "Yakında" vb. durum etiketi.
class DashboardStatusBadge extends StatelessWidget {
  final String label;
  final bool muted;

  const DashboardStatusBadge({
    super.key,
    this.label = 'Yakında',
    this.muted = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: muted
            ? AppColors.borderSoft.withValues(alpha: 0.6)
            : AppColors.accentTurquoise.withValues(alpha: 0.14),
        borderRadius: AppRadius.smallBorder,
        border: Border.all(
          color: muted ? AppColors.borderSoft : AppColors.accentTurquoise.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: muted ? AppColors.textSecondary : AppColors.accentTurquoise,
        ),
      ),
    );
  }
}
