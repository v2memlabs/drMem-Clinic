import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'app_breakpoints.dart';

/// Genişlik sınıfı — layout kararları için.
enum ResponsiveWidthClass {
  compact,
  tablet,
  desktop,
  wideDesktop,
}

/// Ortak responsive yardımcılar.
abstract final class ResponsiveLayout {
  static ResponsiveWidthClass widthClassFor(double width) {
    if (width >= AppBreakpoints.wideDesktop) {
      return ResponsiveWidthClass.wideDesktop;
    }
    if (width >= AppBreakpoints.desktop) {
      return ResponsiveWidthClass.desktop;
    }
    if (width >= AppBreakpoints.tabletLandscape) {
      return ResponsiveWidthClass.tablet;
    }
    return ResponsiveWidthClass.compact;
  }

  static bool isDesktop(double width) =>
      width >= AppBreakpoints.desktop;

  static bool isWideDesktop(double width) =>
      width >= AppBreakpoints.wideDesktop;

  static bool useDetailTwoColumn(double width) =>
      width >= AppBreakpoints.detailTwoColumn;

  /// Sayfa içi yatay/dikey boşluk — tablet davranışı korunur.
  static EdgeInsets pagePadding(double availableWidth) {
    final wClass = widthClassFor(availableWidth);
    switch (wClass) {
      case ResponsiveWidthClass.wideDesktop:
        return const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
        );
      case ResponsiveWidthClass.desktop:
        return const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        );
      case ResponsiveWidthClass.tablet:
      case ResponsiveWidthClass.compact:
        return const EdgeInsets.all(AppSpacing.md);
    }
  }

  /// AppShell sağ içerik alanı — geniş ekranda hafif yatay nefes.
  static EdgeInsets shellContentPadding(double availableWidth) {
    if (availableWidth >= AppBreakpoints.wideDesktop) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.sm);
    }
    return EdgeInsets.zero;
  }

  static double cappedWidth(double availableWidth, double cap) {
    if (availableWidth >= cap + 32) return cap;
    return availableWidth;
  }

  /// Liste ekranları — desktop'ta içerik alanının tamamını kullanır.
  static double listContentMaxWidth(double availableWidth) {
    if (isDesktop(availableWidth)) return availableWidth;
    return cappedWidth(availableWidth, 1020);
  }

  /// Detay ekranları — desktop'ta geniş; tablette kontrollü cap.
  static double detailContentMaxWidth(double availableWidth) {
    if (isDesktop(availableWidth)) return availableWidth;
    return cappedWidth(availableWidth, AppBreakpoints.detailMaxWidth);
  }

  static bool useFullWidthListLayout(double availableWidth) =>
      isDesktop(availableWidth);

  static bool useFullWidthDetailLayout(double availableWidth) =>
      isDesktop(availableWidth);

  static double formContentMaxWidth(
    double availableWidth, {
    bool longForm = false,
  }) {
    final cap = longForm
        ? AppBreakpoints.formLongMaxWidth
        : AppBreakpoints.formStandardMaxWidth;
    return cappedWidth(availableWidth, cap);
  }

  static int dashboardGridCrossCount(double width) {
    if (width >= AppBreakpoints.dashboardGrid4) return 4;
    if (width >= AppBreakpoints.dashboardGrid3) return 3;
    if (width >= AppBreakpoints.dashboardGrid2) return 2;
    return 1;
  }

  static double dashboardGridAspectRatio(int crossAxisCount) {
    switch (crossAxisCount) {
      case 4:
        return 2.2;
      case 3:
        return 2.35;
      case 2:
        return 2.45;
      default:
        return 2.15;
    }
  }
}

/// AppShell içerik alanı arka plan + hafif padding.
class ResponsiveShellContent extends StatelessWidget {
  final Widget child;

  const ResponsiveShellContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ColoredBox(
          color: AppColors.backgroundSoft,
          child: Padding(
            padding: ResponsiveLayout.shellContentPadding(constraints.maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
