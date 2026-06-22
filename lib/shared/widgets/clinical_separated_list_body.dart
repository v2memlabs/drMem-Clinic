import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Post-op referans liste gövdesi — ayrık kartlar + isteğe bağlı durum legend.
class ClinicalSeparatedListBody extends StatelessWidget {
  final List<Widget> children;
  final Widget? legend;

  const ClinicalSeparatedListBody({
    super.key,
    required this.children,
    this.legend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => children[index],
          ),
        ),
        if (legend != null) ...[
          const SizedBox(height: AppSpacing.sm),
          legend!,
        ],
      ],
    );
  }
}
