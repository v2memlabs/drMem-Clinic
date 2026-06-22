import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'premium_surface.dart';

const String kDisplayUnspecified = 'Belirtilmedi';

String displayField(String value) =>
    value.trim().isEmpty ? kDisplayUnspecified : value.trim();

/// Detay ekranı section satırı.
class InfoSectionRow {
  final String label;
  final String value;
  final bool emphasize;

  const InfoSectionRow(
    this.label,
    this.value, {
    this.emphasize = false,
  });
}

/// Detay ekranında label/value bölüm kartı.
class InfoSectionCard extends StatelessWidget {
  final String title;
  final List<InfoSectionRow> rows;
  final EdgeInsetsGeometry? margin;

  const InfoSectionCard({
    super.key,
    required this.title,
    required this.rows,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final allEmpty = rows.every((r) => r.value == kDisplayUnspecified);

    return Container(
      margin: margin,
      decoration: PremiumSurface.panel(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.trim().isNotEmpty) ...[
              PremiumSurface.sectionTitle(context, title),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (allEmpty)
              Text(
                'Bu bölümde kayıtlı bilgi yok.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              for (final row in rows) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 108,
                        child: Text(
                          row.label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.value,
                          style: (row.emphasize
                                  ? Theme.of(context).textTheme.bodyMedium
                                  : Theme.of(context).textTheme.bodySmall)
                              ?.copyWith(
                                fontWeight:
                                    row.emphasize ? FontWeight.w600 : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                          maxLines: row.emphasize ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
