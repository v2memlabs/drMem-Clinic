import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Detay/form ekranları — üst üste panel kartlar (Post-op referans).
class ClinicalStackedSections extends StatelessWidget {
  final List<Widget> children;

  const ClinicalStackedSections({super.key, required this.children});

  static const double sectionSpacing = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: sectionSpacing),
          children[i],
        ],
      ],
    );
  }
}
