import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../widgets/clinical_stacked_sections.dart';
import 'app_breakpoints.dart';
import 'responsive_layout.dart';

/// Liste ekranları — ortalanmış max genişlik + responsive padding.
class ResponsiveListPage extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveListPage({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = ResponsiveLayout.pagePadding(width);
        final content = Padding(padding: padding, child: child);

        if (maxWidth != null) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: content,
            ),
          );
        }

        if (ResponsiveLayout.useFullWidthListLayout(width)) {
          return SizedBox(width: double.infinity, child: content);
        }

        final cap = ResponsiveLayout.listContentMaxWidth(width);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cap),
            child: content,
          ),
        );
      },
    );
  }
}

/// Detay ekranları — liste ile aynı genişlik ve kaydırma (Post-op referans).
class ResponsiveDetailPage extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final bool scrollable;

  const ResponsiveDetailPage({
    super.key,
    required this.child,
    this.maxWidth,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveListPage(
      maxWidth: maxWidth,
      child: scrollable ? SingleChildScrollView(child: child) : child,
    );
  }
}

/// Detay section kartları — tek kolon, Post-op ile aynı aralık.
@Deprecated('Use ClinicalStackedSections instead')
class ResponsiveSectionColumns extends StatelessWidget {
  final List<Widget> children;
  final double twoColumnMinWidth;
  final double spacing;

  const ResponsiveSectionColumns({
    super.key,
    required this.children,
    this.twoColumnMinWidth = AppBreakpoints.detailTwoColumn,
    this.spacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicalStackedSections(children: children);
  }
}
