import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'status_chip.dart';

/// Küçük hasta/etiket chip'i — nötr, kompakt.
class ClinicalTagChip extends StatelessWidget {
  final String label;

  const ClinicalTagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Klinik workbench liste satırı — gölgesiz, panel divider ile ayrılır.
class ClinicalListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? demographicLine;
  final List<String> metaLines;
  final List<String> tags;
  final int maxVisibleTags;
  final String? semanticChipLabel;
  final StatusChipTone? semanticChipTone;
  final String? neutralChipLabel;
  final Color? statusMarkerColor;
  final String? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool enabled;
  final bool compact;

  static const int maxMetaLines = 2;

  const ClinicalListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.demographicLine,
    this.metaLines = const [],
    this.tags = const [],
    this.maxVisibleTags = 3,
    this.semanticChipLabel,
    this.semanticChipTone,
    this.neutralChipLabel,
    this.statusMarkerColor,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.enabled = true,
    this.compact = false,
    this.showSemanticStatusChip = true,
  });

  /// false → [semanticChipLabel] yalnızca kritik durumlarda kullanılmalı.
  final bool showSemanticStatusChip;

  bool get _showSemanticChip =>
      showSemanticStatusChip &&
      semanticChipLabel != null &&
      semanticChipLabel!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final effectiveMeta = metaLines
        .where((m) => m.trim().isNotEmpty)
        .take(maxMetaLines)
        .toList();
    final visibleTags = tags.take(maxVisibleTags).toList();
    final overflowTagCount = tags.length - visibleTags.length;

    final verticalPad = compact ? AppSpacing.xs : AppSpacing.sm;

    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: verticalPad,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (statusMarkerColor != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, right: AppSpacing.xs),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusMarkerColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (demographicLine != null &&
                              demographicLine!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              demographicLine!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null && trailing!.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        trailing!,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
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
                for (final line in effectiveMeta) ...[
                  const SizedBox(height: 2),
                  Text(
                    line,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (visibleTags.isNotEmpty ||
                    overflowTagCount > 0 ||
                    _showSemanticChip ||
                    neutralChipLabel != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xxs,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_showSemanticChip)
                        StatusChip(
                          label: semanticChipLabel!,
                          tone: semanticChipTone ?? StatusChipTone.neutral,
                        ),
                      if (neutralChipLabel != null)
                        StatusChip(
                          label: neutralChipLabel!,
                          tone: StatusChipTone.neutral,
                        ),
                      for (final tag in visibleTags) ClinicalTagChip(label: tag),
                      if (overflowTagCount > 0)
                        ClinicalTagChip(label: '+$overflowTagCount etiket'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (showChevron && onTap != null)
            IconButton(
              onPressed: enabled ? onTap : null,
              icon: const Icon(Icons.chevron_right, size: 20),
              tooltip: 'Detay',
              visualDensity: VisualDensity.compact,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );

    if (!enabled) {
      content = Opacity(opacity: 0.55, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        hoverColor: AppColors.accentTurquoise.withValues(alpha: 0.06),
        focusColor: AppColors.accentTurquoise.withValues(alpha: 0.08),
        child: content,
      ),
    );
  }
}
