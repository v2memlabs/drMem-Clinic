import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'premium_surface.dart';

/// Form bölümü — divider veya panel kart (detay [InfoSectionCard] ile uyumlu).
class FormSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool showIconBadge;
  final List<Widget> children;
  final bool compact;
  final bool bordered;

  /// true → [PremiumSurface.panel] kart; detay/liste ile aynı görünüm.
  final bool panel;
  final EdgeInsetsGeometry? margin;
  final Widget? titleTrailing;

  const FormSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
    this.showIconBadge = false,
    this.compact = false,
    this.bordered = true,
    this.panel = true,
    this.margin,
    this.titleTrailing,
  });

  double get _fieldGap => compact ? AppSpacing.xs : AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    if (panel) {
      return Container(
        margin: margin,
        decoration: PremiumSurface.panel(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PremiumSurface.sectionTitle(context, title),
                  ),
                  if (titleTrailing != null) titleTrailing!,
                ],
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: _fieldGap),
                children[i],
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.only(
        bottom: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      decoration: bordered
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSoft, width: 1),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                if (showIconBadge)
                  PremiumSurface.iconBadge(icon: icon!, size: 32, compact: true)
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 18, color: AppColors.textSecondary),
                  ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: _fieldGap),
            children[i],
          ],
        ],
      ),
    );
  }
}
