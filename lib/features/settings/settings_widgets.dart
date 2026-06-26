import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/premium_surface.dart';

/// Ayarlar alt sayfalarında ortak section kartı (gradient başlık yok).
class SettingsSectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final Widget? footer;

  const SettingsSectionCard({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: PremiumSurface.card(),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: AppColors.navy),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...children,
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.sm),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const SettingsReadOnlyRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SettingsShellNote extends StatelessWidget {
  final String message;

  const SettingsShellNote({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
      ),
    );
  }
}

class SettingsImagePlaceholder extends StatelessWidget {
  final String label;
  final IconData icon;
  final double height;

  const SettingsImagePlaceholder({
    super.key,
    required this.label,
    this.icon = Icons.image_outlined,
    this.height = 96,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: muted, size: 32),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsDisabledField extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;

  const SettingsDisabledField({
    super.key,
    required this.label,
    this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        enabled: false,
        initialValue: value ?? hint ?? '',
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          hintText: hint,
        ),
      ),
    );
  }
}
