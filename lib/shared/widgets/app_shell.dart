import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/session/auth_session_lifecycle.dart';
import '../../core/constants/app_branding.dart';
import '../../features/settings/settings_product_labels.dart';
import '../../core/navigation/app_nav_config.dart';
import '../../core/data/backend_config.dart';
import '../../core/session/active_tenant_context_store.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../layout/app_breakpoints.dart';
import '../layout/responsive_layout.dart';
import 'marquee_text.dart';

/// Sol sidebar + içerik alanı. Premium koyu lacivert navigasyon (Faz 3).
class AppShell extends StatefulWidget {
  final Widget child;
  final String title;

  const AppShell({
    super.key,
    required this.child,
    this.title = 'Klinik',
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final Map<String, bool> _sectionExpanded = {};
  String? _lastLocation;

  static const double _sidebarBreakpoint = AppBreakpoints.sidebarExpanded;
  static const double _sidebarWideWidth = 252;
  static const double _sidebarNarrowWidth = 64;

  static Color get _sidebarText => Colors.white.withValues(alpha: 0.92);
  static Color get _sidebarTextMuted => Colors.white.withValues(alpha: 0.55);
  static Color get _sidebarDivider => Colors.white.withValues(alpha: 0.12);

  void _syncExpandedForLocation(String location, List<AppNavSection> sections) {
    if (_lastLocation == location) return;
    _lastLocation = location;
    for (final section in sections) {
      if (isNavSectionActive(location, section)) {
        _sectionExpanded[section.expansionKey] = true;
      }
    }
  }

  bool _isSectionExpanded(AppNavSection section, String location) {
    if (section.hideTitle) return true;
    if (_sectionExpanded.containsKey(section.expansionKey)) {
      return _sectionExpanded[section.expansionKey]!;
    }
    return isNavSectionActive(location, section);
  }

  void _toggleSection(AppNavSection section, String location) {
    setState(() {
      final currentlyExpanded = _isSectionExpanded(section, location);
      _sectionExpanded[section.expansionKey] = !currentlyExpanded;
    });
  }

  void _logout(BuildContext context) {
    AuthSessionLifecycle.signOut(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthSession.currentUser;
    final location = GoRouterState.of(context).location;
    final dashboardItem = buildAppNavDashboardItem();
    final sections = buildAppNavSections();
    _syncExpandedForLocation(location, sections);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _sidebarBreakpoint;
        final sidebarWidth = isWide ? _sidebarWideWidth : _sidebarNarrowWidth;

        return Scaffold(
          body: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.sidebarBrandGradient,
                ),
                child: SizedBox(
                  width: sidebarWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListenableBuilder(
                        listenable: appSettingsController,
                        builder: (context, _) {
                          final tenantCtx = ActiveTenantContextStore.current;
                          final useSupabaseTenant =
                              AppBackendConfig.isSupabase && tenantCtx != null;

                          final clinicName = useSupabaseTenant
                              ? (tenantCtx.tenant.name.trim().isNotEmpty
                                  ? tenantCtx.tenant.name
                                  : AppBranding.clinicName)
                              : (appSettingsController.settings.clinicName
                                      .trim()
                                      .isNotEmpty
                                  ? appSettingsController.settings.clinicName
                                  : AppBranding.clinicName);
                          final specialty = useSupabaseTenant
                              ? (tenantCtx.tenant.specialty.trim().isNotEmpty
                                  ? tenantCtx.tenant.specialty.trim()
                                  : '')
                              : (appSettingsController.settings.specialty
                                      .trim()
                                      .isNotEmpty
                                  ? appSettingsController.settings.specialty
                                      .trim()
                                  : 'Ortopedi ve Travmatoloji Uzmanı');
                          return _SidebarBrandHeader(
                            isWide: isWide,
                            clinicName: clinicName,
                            specialty: specialty,
                          );
                        },
                      ),
                      Divider(height: 1, thickness: 1, color: _sidebarDivider),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          children: [
                            if (dashboardItem != null && dashboardItem.visible())
                              _NavTile(
                                item: dashboardItem,
                                isWide: isWide,
                                isActive: isNavItemActive(location, dashboardItem),
                                onTap: () => context.go(dashboardItem.route),
                              ),
                            for (final section in sections)
                              if (isWide)
                                _CollapsibleNavSection(
                                  section: section,
                                  location: location,
                                  isExpanded: _isSectionExpanded(section, location),
                                  onToggle: () => _toggleSection(section, location),
                                  onItemTap: (route) => context.go(route),
                                )
                              else
                                for (final item in section.items)
                                  _NavTile(
                                    item: item,
                                    isWide: false,
                                    isActive: isNavItemActive(location, item),
                                    onTap: () => context.go(item.route),
                                  ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: _sidebarDivider),
                      _SidebarUserFooter(
                        isWide: isWide,
                        displayName: user?.displayName ?? 'Misafir',
                        roleLabel: user != null
                            ? SettingsProductLabels.roleLabel(user.role)
                            : 'Giriş yapılmadı',
                        onLogout: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ResponsiveShellContent(child: widget.child),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarBrandHeader extends StatelessWidget {
  final bool isWide;
  final String clinicName;
  final String specialty;

  const _SidebarBrandHeader({
    required this.isWide,
    required this.clinicName,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleStyle = TextStyle(
      fontSize: 11,
      height: 1.3,
      color: _AppShellState._sidebarTextMuted,
      fontWeight: FontWeight.w500,
    );

    if (!isWide) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
        child: Tooltip(
          message: '$clinicName\n$specialty',
          child: Center(
            child: _BrandIcon(size: 36),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandIcon(size: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: MarqueeText(
                    text: clinicName,
                    style: TextStyle(
                      color: _AppShellState._sidebarText,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  specialty,
                  style: subtitleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentTurquoise.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.accentTurquoise.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Demo',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: AppColors.accentTurquoise.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandIcon extends StatelessWidget {
  final double size;

  const _BrandIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: AppRadius.mediumBorder,
        border: Border.all(color: AppColors.accentTurquoise.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          AppBranding.iconAsset,
          width: size - 12,
          height: size - 12,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _SidebarUserFooter extends StatelessWidget {
  final bool isWide;
  final String displayName;
  final String roleLabel;
  final VoidCallback onLogout;

  const _SidebarUserFooter({
    required this.isWide,
    required this.displayName,
    required this.roleLabel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: AppRadius.mediumBorder,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accentTurquoise.withValues(alpha: 0.22),
                  child: Icon(Icons.person, size: 20, color: _AppShellState._sidebarText),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: _AppShellState._sidebarText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _RoleChip(label: roleLabel),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Çıkış',
                  child: IconButton(
                    onPressed: onLogout,
                    icon: Icon(Icons.logout, size: 20, color: _AppShellState._sidebarTextMuted),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(AppSpacing.xs),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          Tooltip(
            message: '$displayName\n$roleLabel',
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accentTurquoise.withValues(alpha: 0.22),
              child: Icon(Icons.person_outline, size: 18, color: _AppShellState._sidebarText),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Tooltip(
            message: 'Çıkış',
            child: IconButton(
              icon: Icon(Icons.logout, size: 22, color: _AppShellState._sidebarTextMuted),
              onPressed: onLogout,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;

  const _RoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentTurquoise.withValues(alpha: 0.18),
        borderRadius: AppRadius.smallBorder,
        border: Border.all(color: AppColors.accentTurquoise.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.accentTurquoise.withValues(alpha: 0.95),
          letterSpacing: 0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CollapsibleNavSection extends StatelessWidget {
  final AppNavSection section;
  final String location;
  final bool isExpanded;
  final VoidCallback onToggle;
  final void Function(String route) onItemTap;

  const _CollapsibleNavSection({
    required this.section,
    required this.location,
    required this.isExpanded,
    required this.onToggle,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: _AppShellState._sidebarTextMuted,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w600,
      fontSize: 11,
    );

    final itemTiles = [
      for (final item in section.items)
        _NavTile(
          item: item,
          isWide: true,
          isActive: isNavItemActive(location, item),
          onTap: () => onItemTap(item.route),
        ),
    ];

    if (section.hideTitle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section.dividerBefore)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.xs),
              child: Divider(height: 1, thickness: 1, color: _AppShellState._sidebarDivider),
            ),
          ...itemTiles,
          const SizedBox(height: AppSpacing.xxs),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.dividerBefore)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 0),
            child: Divider(height: 1, thickness: 1, color: _AppShellState._sidebarDivider),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: AppRadius.smallBorder,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xxs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      section.title.toUpperCase(),
                      style: labelStyle,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: _AppShellState._sidebarTextMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded) ...itemTiles,
        const SizedBox(height: AppSpacing.xxs),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  final AppNavItem item;
  final bool isWide;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isWide,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smallBorder,
        hoverColor: Colors.white.withValues(alpha: 0.06),
        focusColor: Colors.white.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? AppSpacing.sm : 0,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smallBorder,
            color: isActive
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            border: isActive
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1,
                  )
                : null,
          ),
          child: isWide
              ? Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isActive
                          ? AppColors.accentTurquoise
                          : _AppShellState._sidebarTextMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? _AppShellState._sidebarText : _AppShellState._sidebarTextMuted,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: isActive
                        ? AppColors.accentTurquoise
                        : _AppShellState._sidebarTextMuted,
                  ),
                ),
        ),
      ),
    );

    if (isWide) return content;

    return Tooltip(message: item.label, child: content);
  }
}
