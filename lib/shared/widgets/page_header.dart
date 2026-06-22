import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../layout/app_breakpoints.dart';
import '../../features/dashboard/widgets/dashboard_notification_alert_button.dart';
import 'date_time_chip.dart';
import 'premium_surface.dart';
import 'shell_clock_chip.dart';

/// İçerik workbench sayfa başlığı — düz band, gradient yok.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool leadingBack;
  final VoidCallback? onBack;
  final String? fallbackRoute;
  final List<Widget>? actions;
  final Widget? trailing;
  final bool compact;
  final IconData? icon;
  final bool showIconBadge;
  final bool showDateTime;
  final DateTime? dateTime;

  /// AppShell ekranlarında canlı tarih/saat pill — başlıkla aynı satırda.
  final bool showShellDateTime;
  final int? alertCount;
  final VoidCallback? onAlertTap;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingBack = false,
    this.onBack,
    this.fallbackRoute,
    this.actions,
    this.trailing,
    this.compact = false,
    this.icon,
    this.showIconBadge = false,
    this.showDateTime = false,
    this.dateTime,
    this.showShellDateTime = true,
    this.alertCount,
    this.onAlertTap,
  });

  static String weekdayTr(DateTime d) {
    const names = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return names[d.weekday - 1];
  }

  static void navigateBack(
    BuildContext context, {
    VoidCallback? onBack,
    String? fallbackRoute,
  }) {
    if (onBack != null) {
      onBack();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (fallbackRoute != null && fallbackRoute.isNotEmpty) {
      context.go(fallbackRoute);
    }
  }

  List<Widget> get _actionWidgets {
    if (actions != null && actions!.isNotEmpty) return actions!;
    if (trailing != null) return [trailing!];
    return const [];
  }

  bool get _hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  bool get _showsClock => showShellDateTime || showDateTime;

  @override
  Widget build(BuildContext context) {
    final actionList = _actionWidgets;
    final now = dateTime ?? DateTime.now();
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )
        : Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppBreakpoints.pageHeaderStack;
        final hasAlerts = (alertCount ?? 0) > 0 && onAlertTap != null;
        final stackActionsBelow = narrow && actionList.isNotEmpty;

        Widget titleColumn() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: titleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_hasSubtitle) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );
        }

        Widget leadingIcon() {
          if (icon == null) return const SizedBox.shrink();
          if (showIconBadge) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: PremiumSurface.iconBadge(
                icon: icon!,
                compact: compact,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
            child: Icon(icon, size: 22, color: AppColors.textSecondary),
          );
        }

        Widget leadingRow() {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingBack) ...[
                _BackButton(
                  onPressed: () => navigateBack(
                    context,
                    onBack: onBack,
                    fallbackRoute: fallbackRoute,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              leadingIcon(),
              Expanded(child: titleColumn()),
            ],
          );
        }

        Widget actionsWrap() {
          if (actionList.isEmpty) return const SizedBox.shrink();
          return Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: actionList,
          );
        }

        Widget clockChip() {
          if (showDateTime) {
            return DateTimeChip(dateTime: now);
          }
          if (showShellDateTime) {
            return const ShellClockChip();
          }
          return const SizedBox.shrink();
        }

        Widget metaTrailing() {
          final parts = <Widget>[];
          if (hasAlerts) {
            parts.add(
              DashboardNotificationAlertButton(
                count: alertCount!,
                onTap: onAlertTap!,
              ),
            );
          }
          if (_showsClock) {
            if (parts.isNotEmpty) {
              parts.add(const SizedBox(width: AppSpacing.sm));
            }
            parts.add(clockChip());
          }
          if (parts.isEmpty) return const SizedBox.shrink();
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: parts,
          );
        }

        final padding = EdgeInsets.only(
          bottom: AppSpacing.sm,
          top: leadingBack ? 0 : AppSpacing.xxs,
        );

        final titleRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leadingRow()),
            if (!stackActionsBelow && actionList.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.md),
              actionsWrap(),
            ],
            if (hasAlerts || _showsClock) ...[
              const SizedBox(width: AppSpacing.md),
              metaTrailing(),
            ],
          ],
        );

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: padding,
          decoration: PremiumSurface.contentHeaderBand(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleRow,
              if (stackActionsBelow) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: actionsWrap(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
      tooltip: 'Geri',
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.all(6),
        minimumSize: const Size(36, 36),
      ),
    );
  }
}
