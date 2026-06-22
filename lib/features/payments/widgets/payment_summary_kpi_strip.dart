import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/premium_surface.dart';

/// Ödemeler listesi — filtrelenmiş kayıtlar için kompakt özet şeridi.
class PaymentSummaryKpiStrip extends StatelessWidget {
  final String totalAccrual;
  final String totalPaid;
  final String pendingAmount;
  final String pendingCount;

  const PaymentSummaryKpiStrip({
    super.key,
    required this.totalAccrual,
    required this.totalPaid,
    required this.pendingAmount,
    required this.pendingCount,
  });

  static const _labels = (
    accrual: 'Toplam Tahakkuk',
    paid: 'Tahsil Edilen',
    balance: 'Kalan Bakiye',
    pending: 'Bekleyen Kayıt',
  );

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (_labels.accrual, totalAccrual),
      (_labels.paid, totalPaid),
      (_labels.balance, pendingAmount),
      (_labels.pending, pendingCount),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: PremiumSurface.panel(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final singleRow = constraints.maxWidth >= 600;
          if (singleRow) {
            return Row(
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  if (i > 0) _verticalDivider(),
                  Expanded(
                    child: _PaymentSummaryKpiTile(
                      label: metrics[i].$1,
                      value: metrics[i].$2,
                    ),
                  ),
                ],
              ],
            );
          }

          final tileWidth = (constraints.maxWidth - AppSpacing.xs) / 2;
          return Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final m in metrics)
                SizedBox(
                  width: tileWidth,
                  child: _PaymentSummaryKpiTile(label: m.$1, value: m.$2),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.borderSoft,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}

class _PaymentSummaryKpiTile extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentSummaryKpiTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: muted,
                  height: 1.2,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
