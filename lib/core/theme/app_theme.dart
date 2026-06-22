import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_typography.dart';

/// Global [ThemeData] — Premium UI Foundation (Faz 1).
///
/// Ekran/layout redesign bu dosyada yapılmaz; token'lar sonraki fazlar için hazırlanır.
/// Bkz. [PREMIUM_UI.md].
class AppTheme {
  AppTheme._();

  /// Geriye dönük alias — [AppColors.primaryDeepTeal].
  static const Color primary = AppColors.primaryDeepTeal;

  /// Geriye dönük alias — [AppColors.backgroundSoft].
  static const Color surface = AppColors.backgroundSoft;

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = _colorScheme(brightness);

    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.smallBorder);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight ? AppColors.backgroundSoft : colorScheme.surface,
      textTheme: AppTypography.textTheme(colorScheme, brightness: brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.backgroundSoft : colorScheme.surface,
        foregroundColor: isLight ? AppColors.textPrimary : colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme(colorScheme, brightness: brightness).titleMedium,
      ),
      cardColor: isLight ? AppColors.surfaceCard : colorScheme.surfaceContainerHighest,
      cardTheme: CardThemeData(
        color: isLight ? AppColors.surfaceCard : null,
        elevation: 0,
        shadowColor: AppShadows.cardShadowColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardBorder,
          side: BorderSide(color: isLight ? AppColors.borderSoft : colorScheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.borderSoft : colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDeepTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryDeepTeal.withValues(alpha: 0.38),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.62),
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDeepTeal,
          foregroundColor: Colors.white,
          padding: buttonPadding,
          shape: buttonShape,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDeepTeal,
          padding: buttonPadding,
          shape: buttonShape,
          side: const BorderSide(color: AppColors.borderSoft),
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused) || states.contains(WidgetState.pressed)) {
              return const BorderSide(color: AppColors.accentTurquoise, width: 1.5);
            }
            return const BorderSide(color: AppColors.borderSoft);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: buttonShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: isLight,
        fillColor: isLight ? AppColors.inputFillLight : colorScheme.surfaceContainerHighest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: AppRadius.smallBorder),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallBorder,
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallBorder,
          borderSide: const BorderSide(color: AppColors.accentTurquoise, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallBorder,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallBorder,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: isLight ? AppColors.textSecondary : colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: isLight ? AppColors.textSecondary.withValues(alpha: 0.85) : colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.backgroundSoft : colorScheme.surfaceContainerHigh,
        selectedColor: AppColors.primaryDeepTeal.withValues(alpha: 0.12),
        disabledColor: AppColors.borderSoft.withValues(alpha: 0.5),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isLight ? AppColors.textPrimary : colorScheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 11,
          color: isLight ? AppColors.textSecondary : colorScheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smallBorder,
          side: BorderSide(color: isLight ? AppColors.borderSoft : colorScheme.outlineVariant),
        ),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.surfaceCard : colorScheme.surfaceContainerHigh,
        elevation: 3,
        shadowColor: AppShadows.cardShadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        titleTextStyle: AppTypography.textTheme(colorScheme, brightness: brightness).titleMedium,
        contentTextStyle: AppTypography.textTheme(colorScheme, brightness: brightness).bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBorder),
        backgroundColor: AppColors.navyDark,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        actionTextColor: AppColors.accentTurquoise,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDeepTeal,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBorder),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.mediumBorder),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBorder),
        elevation: 2,
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  static ColorScheme _colorScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDeepTeal,
      brightness: brightness,
      primary: AppColors.primaryDeepTeal,
      secondary: AppColors.accentTurquoise,
      tertiary: AppColors.navy,
      surface: brightness == Brightness.light ? AppColors.backgroundSoft : null,
    );

    return base.copyWith(
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      primaryContainer: AppColors.primaryDeepTeal.withValues(alpha: brightness == Brightness.light ? 0.12 : 0.24),
      onPrimaryContainer: AppColors.primaryDeepTeal,
      secondaryContainer: AppColors.accentTurquoise.withValues(alpha: brightness == Brightness.light ? 0.14 : 0.22),
      onSecondaryContainer: AppColors.accentTurquoise,
      tertiaryContainer: AppColors.navyDark,
      onTertiaryContainer: Colors.white,
      outline: AppColors.borderSoft,
      outlineVariant: AppColors.borderSoft.withValues(alpha: 0.7),
      error: AppColors.danger,
    );
  }
}
