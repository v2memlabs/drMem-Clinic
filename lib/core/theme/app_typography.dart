import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 textTheme üzerine drMem Clinic tipografi ölçeği.
abstract final class AppTypography {
  static TextTheme textTheme(ColorScheme scheme, {required Brightness brightness}) {
    final base = Typography.material2021(
      platform: TargetPlatform.windows,
    ).black;

    final primary = brightness == Brightness.light
        ? AppColors.textPrimary
        : scheme.onSurface;
    final secondary = brightness == Brightness.light
        ? AppColors.textSecondary
        : scheme.onSurfaceVariant;

    return base.copyWith(
      // Sayfa başlığı
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.25,
      ),
      // Section / dashboard başlığı
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.35,
      ),
      // Gövde
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.45,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      // Label / meta / nav section
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: secondary,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
    );
  }
}
