import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/page_header.dart';
import 'settings_categories.dart';

/// Ayarlar alt sayfası — AppShell + kompakt geri + düz başlık.
class SettingsSubpageScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? fallbackRoute;

  const SettingsSubpageScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: icon,
              leadingBack: true,
              fallbackRoute: fallbackRoute ?? SettingsCategories.hubPath,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
