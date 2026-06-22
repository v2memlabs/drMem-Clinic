import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'premium_surface.dart';

/// Tek panel içinde gölgesiz liste satırları — divider ile ayrılır.
class ClinicalListPanel extends StatelessWidget {
  final List<Widget> children;
  final Widget? header;

  const ClinicalListPanel({
    super.key,
    required this.children,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: PremiumSurface.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[
            header!,
            const Divider(height: 1),
          ],
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 0, endIndent: 0),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Kartsız liste — dış çerçeve yok; satırlar divider ile ayrılır (pilot / düz workbench).
class ClinicalFlatList extends StatelessWidget {
  final List<Widget> children;
  final bool showTopDivider;

  const ClinicalFlatList({
    super.key,
    required this.children,
    this.showTopDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTopDivider)
          Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
          children[i],
        ],
      ],
    );
  }
}

/// Boş liste paneli sarmalayıcısı — dış margin tutarlılığı.
class ClinicalListSection extends StatelessWidget {
  final Widget child;
  final Widget? legend;

  const ClinicalListSection({
    super.key,
    required this.child,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        if (legend != null) legend!,
      ],
    );
  }
}
