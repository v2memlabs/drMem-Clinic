import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// İçerik ekranları için düz/bordered yüzeyler.
///
/// Gradient yalnız login ve sidebar'da ([AppColors.sidebarBrandGradient]).
/// Bkz. [PREMIUM_UI.md].
abstract final class PremiumSurface {
  /// Varsayılan içerik paneli — border, gölge yok.
  static BoxDecoration panel({Color? backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.surfaceCard,
      borderRadius: AppRadius.cardBorder,
      border: Border.all(color: AppColors.borderSoft),
    );
  }

  /// İçerik kartı — varsayılan düz; [elevated] yalnız istisna (sayfa başına max 1).
  static BoxDecoration card({
    bool elevated = false,
    bool accentTopEdge = false,
  }) {
    return BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: AppRadius.cardBorder,
      border: Border.all(color: AppColors.borderSoft),
      boxShadow: elevated ? AppShadows.card : null,
      gradient: accentTopEdge
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accentTurquoise.withValues(alpha: 0.06),
                AppColors.surfaceCard,
              ],
              stops: const [0, 0.35],
            )
          : null,
    );
  }

  /// Sayfa üst başlık bandı — gradient/gölge yok, alt çizgi.
  static BoxDecoration contentHeaderBand() {
    return const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: AppColors.borderSoft, width: 1),
      ),
    );
  }

  /// @deprecated İçerikte [contentHeaderBand] kullanın.
  static BoxDecoration headerPanel() => contentHeaderBand();

  /// FilterBar — düz panel.
  static BoxDecoration filterPanel() {
    return BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: AppRadius.mediumBorder,
      border: Border.all(color: AppColors.borderSoft),
    );
  }

  /// Sol aksan çizgisi (liste satırı — tek turkuaz vurgu).
  static BoxDecoration listAccentRail({Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.accentTurquoise,
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(AppRadius.card),
      ),
    );
  }

  /// Dekoratif rozet — varsayılan kapalı; login dışı sınırlı kullanım.
  static Widget iconBadge({
    required IconData icon,
    double size = 40,
    Color? accent,
    bool compact = false,
  }) {
    final color = accent ?? AppColors.accentTurquoise;
    final dim = compact ? 36.0 : size;
    return Container(
      width: dim,
      height: dim,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.mediumBorder,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, size: compact ? 20 : 22, color: color),
    );
  }

  /// Section başlığı — sade metin; çizgi+badge birlikte kullanılmaz.
  static Widget sectionTitle(
    BuildContext context,
    String title, {
    IconData? icon,
    bool showAccentLine = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showAccentLine) ...[
          Container(
            width: 2,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
