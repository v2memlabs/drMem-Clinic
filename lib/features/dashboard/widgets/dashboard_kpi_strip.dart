import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/premium_surface.dart';

class DashboardKpiMetric {
  final String label;
  final String value;

  const DashboardKpiMetric({
    required this.label,
    required this.value,
  });
}

/// Tek düz panel — 3–4 nötr KPI metriği.
class DashboardKpiStrip extends StatelessWidget {
  final List<DashboardKpiMetric> metrics;
  final bool isLoading;

  const DashboardKpiStrip({
    super.key,
    required this.metrics,
    this.isLoading = false,
  });

  static String formatCount(int? count, {bool unavailable = false}) {
    if (unavailable) return '—';
    if (count == null) return '—';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: PremiumSurface.panel(),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
        ),
      );
    }

    if (metrics.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: PremiumSurface.panel(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 480;
          if (narrow) {
            return Column(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _KpiTile(metric: metrics[i]),
                ],
              ],
            );
          }

          return Row(
            children: [
              for (var i = 0; i < metrics.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.borderSoft,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  ),
                Expanded(child: _KpiTile(metric: metrics[i])),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final DashboardKpiMetric metric;

  const _KpiTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            metric.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
