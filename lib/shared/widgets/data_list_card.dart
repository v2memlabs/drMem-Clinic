import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'premium_surface.dart';
import 'status_chip.dart';

/// Hibrit liste kartı — ameliyat notu gövdesi + Tip 3 durum vurgusu.
class DataListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? metaLine;
  final String? contextLine;
  final List<String> chips;
  final String? trailing;
  final VoidCallback? onTap;
  final Color? accentRailColor;
  final String? semanticChipLabel;
  final StatusChipTone? semanticChipTone;

  const DataListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.metaLine,
    this.contextLine,
    this.chips = const [],
    this.trailing,
    this.onTap,
    this.accentRailColor,
    this.semanticChipLabel,
    this.semanticChipTone,
  });

  bool get _showSemanticChip =>
      semanticChipLabel != null && semanticChipLabel!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        hoverColor: AppColors.accentTurquoise.withValues(alpha: 0.06),
        focusColor: AppColors.accentTurquoise.withValues(alpha: 0.08),
        child: DecoratedBox(
          decoration: PremiumSurface.card(elevated: true),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (accentRailColor != null)
                  Container(
                    width: 3,
                    decoration: PremiumSurface.listAccentRail(
                      color: accentRailColor,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDeepTeal,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (trailing != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTurquoise
                                      .withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smallBorder,
                                  border: Border.all(
                                    color: AppColors.accentTurquoise
                                        .withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Text(
                                  trailing!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.accentTurquoise,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (metaLine != null && metaLine!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            metaLine!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (contextLine != null && contextLine!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            contextLine!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (_showSemanticChip || chips.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xxs,
                            runSpacing: AppSpacing.xxs,
                            children: [
                              if (_showSemanticChip)
                                StatusChip(
                                  label: semanticChipLabel!,
                                  tone: semanticChipTone ?? StatusChipTone.neutral,
                                ),
                              ...chips.map(
                                (label) => Chip(
                                  label: Text(
                                    label,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  side: BorderSide(
                                    color: AppColors.borderSoft.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                  backgroundColor: AppColors.backgroundSoft,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
