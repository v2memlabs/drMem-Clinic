import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'info_section_card.dart';

/// Kartsız detay bölümü — başlık + satırlar, alt divider.
class FlatDetailSection extends StatelessWidget {
  final String title;
  final List<InfoSectionRow> rows;
  final bool showBottomDivider;

  const FlatDetailSection({
    super.key,
    required this.title,
    required this.rows,
    this.showBottomDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleRows =
        rows.where((r) => r.value != kDisplayUnspecified).toList();
    if (visibleRows.isEmpty) return const SizedBox.shrink();

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
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDeepTeal,
            ),
          ),
        ),
        ...visibleRows.map((row) => _DetailRow(row: row)),
        if (showBottomDivider)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final InfoSectionRow row;

  const _DetailRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 148,
            child: Text(
              row.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: row.emphasize ? FontWeight.w600 : FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
