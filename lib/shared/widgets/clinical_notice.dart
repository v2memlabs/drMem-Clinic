import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'premium_surface.dart';
import 'clinical_notice_tone.dart';
import 'clinical_ui_text_sanitizer.dart';

/// Klinik notice — banner/inline bildirim / bilgi kutusu standardı.
///
/// UI güvenliği için teknik terim içeren metinler (eğer yanlışlıkla gelirse)
/// render edilmeden temizlenir.
class ClinicalNoticeAction {
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final Key? key;

  const ClinicalNoticeAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.key,
  });
}

class ClinicalNotice extends StatelessWidget {
  final ClinicalNoticeTone tone;
  final String? title;
  final String message;
  final List<ClinicalNoticeAction> actions;
  final List<Widget> children;
  final bool dense;

  const ClinicalNotice({
    super.key,
    required this.tone,
    this.title,
    required this.message,
    this.actions = const [],
    this.children = const [],
    this.dense = false,
  }) : assert(actions.length <= 2, 'ClinicalNotice max 2 action destekler.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final iconData = _iconForTone(tone);
    final toneColor = _colorForTone(tone);
    final toneSurface = _surfaceForTone(tone);

    final safeTitle = title == null ? null : _sanitizeUiText(title!);
    final safeMessage = _sanitizeUiText(message);

    final padding = dense
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          );

    return Container(
      key: const Key('clinical_notice_root'),
      width: double.infinity,
      padding: padding,
      decoration: PremiumSurface.panel(backgroundColor: toneSurface),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 20, color: toneColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (safeTitle != null && safeTitle.isNotEmpty) ...[
                  Text(
                    safeTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(
                  safeMessage,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  maxLines: dense ? 3 : 5,
                ),
                if (children.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ...children,
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wrap = constraints.maxWidth < 420;
                      return wrap
                          ? Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final a in actions) _actionButton(a),
                              ],
                            )
                          : Row(
                              children: [
                                for (final a in actions) ...[
                                  if (a != actions.first)
                                    const SizedBox(width: AppSpacing.xs),
                                  _actionButton(a),
                                ],
                              ],
                            );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(ClinicalNoticeAction a) {
    final visualDensity = VisualDensity.compact;
    if (a.primary) {
      return FilledButton.tonal(
        key: a.key,
        style: FilledButton.styleFrom(
          visualDensity: visualDensity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
        onPressed: a.onPressed,
        child: Text(a.label),
      );
    }

    return OutlinedButton(
      key: a.key,
      style: OutlinedButton.styleFrom(
        visualDensity: visualDensity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      onPressed: a.onPressed,
      child: Text(a.label),
    );
  }

  String _sanitizeUiText(String input) => ClinicalUiTextSanitizer.sanitize(input);

  static IconData _iconForTone(ClinicalNoticeTone tone) {
    switch (tone) {
      case ClinicalNoticeTone.info:
        return Icons.info_outline;
      case ClinicalNoticeTone.warning:
        return Icons.warning_amber_outlined;
      case ClinicalNoticeTone.danger:
        return Icons.error_outline;
      case ClinicalNoticeTone.success:
        return Icons.check_circle_outline;
      case ClinicalNoticeTone.locked:
        return Icons.lock_outline;
      case ClinicalNoticeTone.notConfigured:
        return Icons.settings_outlined;
      case ClinicalNoticeTone.neutral:
        return Icons.info_outlined;
    }
  }

  static Color _colorForTone(ClinicalNoticeTone tone) {
    switch (tone) {
      case ClinicalNoticeTone.info:
        return AppColors.info;
      case ClinicalNoticeTone.warning:
        return AppColors.warning;
      case ClinicalNoticeTone.danger:
        return AppColors.danger;
      case ClinicalNoticeTone.success:
        return AppColors.success;
      case ClinicalNoticeTone.locked:
      case ClinicalNoticeTone.notConfigured:
      case ClinicalNoticeTone.neutral:
        return AppColors.textSecondary;
    }
  }

  static Color? _surfaceForTone(ClinicalNoticeTone tone) {
    switch (tone) {
      case ClinicalNoticeTone.info:
        return AppColors.infoSurface;
      case ClinicalNoticeTone.warning:
        return AppColors.warningSurface;
      case ClinicalNoticeTone.danger:
        return AppColors.dangerSurface;
      case ClinicalNoticeTone.success:
        return AppColors.successSurface;
      case ClinicalNoticeTone.locked:
      case ClinicalNoticeTone.notConfigured:
      case ClinicalNoticeTone.neutral:
        return null;
    }
  }
}

