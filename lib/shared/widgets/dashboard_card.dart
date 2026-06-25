import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../layout/responsive_layout.dart';
import 'date_time_chip.dart';
import 'premium_surface.dart';

/// Premium hızlı erişim / akış kartı.
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? accentColor;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.accentTurquoise;

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PremiumSurface.iconBadge(
            icon: icon,
            accent: accent,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardBorder,
        hoverColor: AppColors.accentTurquoise.withValues(alpha: 0.06),
        focusColor: AppColors.accentTurquoise.withValues(alpha: 0.08),
        child: DecoratedBox(
          decoration: PremiumSurface.card(elevated: false),
          child: content,
        ),
      ),
    );
  }
}

/// Dashboard sayfa başlığı + tarih/saat.
class DashboardScreenHeader extends StatelessWidget {
  final String title;
  final DateTime dateTime;

  const DashboardScreenHeader({
    super.key,
    required this.title,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDeepTeal,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        DateTimeChip(dateTime: dateTime),
      ],
    );
  }
}

/// Responsive dashboard kart ızgarası.
class DashboardCardGrid extends StatefulWidget {
  final List<Widget> children;

  const DashboardCardGrid({super.key, required this.children});

  @override
  State<DashboardCardGrid> createState() => _DashboardCardGridState();
}

class _DashboardCardGridState extends State<DashboardCardGrid> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollHint);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollHint);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScroll = position.maxScrollExtent > 4;
    final notAtBottom = position.pixels < position.maxScrollExtent - 4;
    final show = canScroll && notAtBottom;
    if (show != _showScrollHint) {
      setState(() => _showScrollHint = show);
    }
  }

  void _scheduleOverflowCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateScrollHint();
    });
  }

  int _crossAxisCount(double width) =>
      ResponsiveLayout.dashboardGridCrossCount(width);

  double _childAspectRatio(int crossAxisCount) =>
      ResponsiveLayout.dashboardGridAspectRatio(crossAxisCount);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _scheduleOverflowCheck();
        final crossAxisCount = _crossAxisCount(constraints.maxWidth);
        final aspectRatio = _childAspectRatio(crossAxisCount);

        return Stack(
          children: [
            GridView.count(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: aspectRatio,
              padding: EdgeInsets.only(bottom: _showScrollHint ? 20 : 0),
              children: widget.children,
            ),
            if (_showScrollHint)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: ColoredBox(
                    color: AppColors.backgroundSoft.withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 2),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.textSecondary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
