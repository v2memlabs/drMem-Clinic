import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'coming_soon_action.dart';
import 'premium_surface.dart';

/// Tek bir detay aksiyonu.
class DetailAction {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;

  /// Gerçek işlem yok; devre dışı + Yakında etiketi gösterilir.
  final bool comingSoon;

  const DetailAction({
    required this.label,
    this.onPressed,
    this.filled = false,
    this.icon,
    this.comingSoon = false,
  });
}

/// Detay ekranı alt klinik işlem butonları — responsive wrap/grid.
class DetailActionsPanel extends StatelessWidget {
  final String title;
  final List<DetailAction> actions;
  final bool flat;
  final double topSpacing;

  const DetailActionsPanel({
    super.key,
    this.title = 'Klinik İşlemler',
    required this.actions,
    this.flat = false,
    this.topSpacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    final visible = actions
        .where((a) => a.onPressed != null || a.comingSoon)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (flat)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderSoft,
            ),
          ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDeepTeal,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final children = visible.map(_buildButton).toList();

            if (wide) {
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: children,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.xs),
                  children[i],
                ],
              ],
            );
          },
        ),
      ],
    );

    if (flat) {
      return Padding(
        padding: EdgeInsets.only(top: topSpacing),
        child: content,
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: DecoratedBox(
        decoration: PremiumSurface.panel(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: content,
        ),
      ),
    );
  }

  Widget _buildButton(DetailAction action) {
    if (action.comingSoon) {
      return ComingSoonOutlinedButton(label: action.label);
    }
    if (action.filled) {
      if (action.icon != null) {
        return FilledButton.icon(
          onPressed: action.onPressed,
          icon: Icon(action.icon, size: 18),
          label: Text(action.label),
        );
      }
      return FilledButton(
        onPressed: action.onPressed,
        child: Text(action.label),
      );
    }
    if (action.icon != null) {
      return OutlinedButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon, size: 18),
        label: Text(action.label),
      );
    }
    return OutlinedButton(
      onPressed: action.onPressed,
      child: Text(action.label),
    );
  }
}
