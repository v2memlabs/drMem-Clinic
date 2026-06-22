import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';
import '../layout/responsive_layout.dart';

/// Dashboard içerik alanı — geniş ekranda max genişlik.
class DashboardPageBody extends StatelessWidget {
  final Widget child;

  const DashboardPageBody({super.key, required this.child});

  static const double maxContentWidth = AppBreakpoints.dashboardMaxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cap = ResponsiveLayout.cappedWidth(
          constraints.maxWidth,
          maxContentWidth,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cap),
            child: child,
          ),
        );
      },
    );
  }
}
