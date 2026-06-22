import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'clinical_notice_tone.dart';
import 'clinical_ui_text_sanitizer.dart';
import 'premium_surface.dart';

/// Klinik state message — empty/error/notConfigured/loading için kompakt blok.
///
/// UI’da teknik detay sızdırmaz; metinler çağıran katman tarafından
/// kullanıcı dilinde sağlanmalıdır.
class ClinicalStateMessage extends StatelessWidget {
  final ClinicalNoticeTone tone;
  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback? onRetry;
  final Widget? action;

  const ClinicalStateMessage._({
    required this.tone,
    required this.icon,
    required this.title,
    this.description,
    this.onRetry,
    this.action,
  });

  static const String genericLoadFailure =
      'Kayıtlar yüklenirken bir sorun oluştu. Lütfen tekrar deneyin.';

  factory ClinicalStateMessage.loading({required String message}) {
    return ClinicalStateMessage._(
      tone: ClinicalNoticeTone.neutral,
      icon: Icons.hourglass_top_outlined,
      title: message,
    );
  }

  factory ClinicalStateMessage.empty({
    required IconData icon,
    required String title,
    String? description,
    Widget? action,
  }) {
    return ClinicalStateMessage._(
      tone: ClinicalNoticeTone.neutral,
      icon: icon,
      title: title,
      description: description,
      action: action,
    );
  }

  factory ClinicalStateMessage.notConfigured({
    required IconData icon,
    required String title,
    String? description,
  }) {
    return ClinicalStateMessage._(
      tone: ClinicalNoticeTone.notConfigured,
      icon: icon,
      title: title,
      description: description,
    );
  }

  factory ClinicalStateMessage.error({
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onRetry,
  }) {
    return ClinicalStateMessage._(
      tone: ClinicalNoticeTone.danger,
      icon: icon,
      title: title,
      description: description,
      onRetry: onRetry,
    );
  }

  /// Güvenli liste/detay hata açıklaması — teknik metinleri generic mesaja çevirir.
  static String safeErrorDescription(String? message) {
    if (message == null || message.trim().isEmpty) {
      return genericLoadFailure;
    }
    final trimmed = message.trim();
    if (ClinicalUiTextSanitizer.containsForbiddenToken(trimmed)) {
      return genericLoadFailure;
    }
    final sanitized = ClinicalUiTextSanitizer.sanitize(trimmed);
    if (sanitized == '—' || sanitized.length < 4) {
      return genericLoadFailure;
    }
    return sanitized;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final safeTitle = _sanitizeUiText(title);
    final safeDescription =
        description == null ? null : _sanitizeUiText(description!);

    final toneColor = _colorForTone(tone);
    final toneSurface = _surfaceForTone(tone);

    if (tone == ClinicalNoticeTone.neutral &&
        icon == Icons.hourglass_top_outlined &&
        onRetry == null &&
        action == null &&
        description == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                safeTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: PremiumSurface.panel(backgroundColor: toneSurface),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: toneColor),
              const SizedBox(height: AppSpacing.sm),
              Text(
                safeTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (safeDescription != null && safeDescription.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  safeDescription,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.sm),
                action!,
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Tekrar dene'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _sanitizeUiText(String input) => ClinicalUiTextSanitizer.sanitize(input);

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
