import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// Kompakt KPI / metrik kartı (dashboard üst sırası).
class DashboardKpiCard extends StatelessWidget {
  final String value;
  final String label;
  final String? hint;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? accentColor;

  const DashboardKpiCard({
    super.key,
    required this.value,
    required this.label,
    this.hint,
    required this.icon,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.accentTurquoise;

    final child = Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: AppRadius.mediumBorder,
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDeepTeal,
                        height: 1.1,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
        ],
      ),
    );

    return Material(
      color: AppColors.surfaceCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: const BorderSide(color: AppColors.borderSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardBorder,
            boxShadow: AppShadows.card,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// KPI kartları için responsive satır.
class DashboardKpiRow extends StatelessWidget {
  final List<Widget> children;

  const DashboardKpiRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = w >= 1000 ? 4 : (w >= 520 ? 2 : 1);
        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xs),
                children[i],
              ],
            ],
          );
        }
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          final end = (i + columns > children.length) ? children.length : i + columns;
          final chunk = children.sublist(i, end);
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < chunk.length; j++) ...[
                  if (j > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(child: chunk[j]),
                ],
              ],
            ),
          );
          if (end < children.length) {
            rows.add(const SizedBox(height: AppSpacing.xs));
          }
        }
        return Column(children: rows);
      },
    );
  }
}
