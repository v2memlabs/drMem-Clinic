import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'clinical_list_status_tones.dart';
import 'status_chip.dart';

class ClinicalStatusLegendItem {
  final String label;
  final StatusChipTone tone;
  final Color? color;

  const ClinicalStatusLegendItem({
    required this.label,
    required this.tone,
    this.color,
  });
}

/// Renk kodlu listeler için kompakt açıklama anahtarı.
class ClinicalStatusLegend extends StatelessWidget {
  final String title;
  final List<ClinicalStatusLegendItem> items;

  const ClinicalStatusLegend({
    super.key,
    this.title = 'Durum renkleri',
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final item in items)
                _LegendEntry(
                  label: item.label,
                  color: item.color ??
                      ClinicalListStatusTones.markerColorForTone(item.tone) ??
                      AppColors.textSecondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendEntry({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
