import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../shared/layout/app_breakpoints.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/page_header.dart';
import 'settings_categories.dart';
import 'settings_category_card.dart';

/// Ayarlar hub — kategori kartları.
class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = SettingsCategories.visibleForCurrentUser();
    final isDoctor = AuthSession.canEditClinicProfile;

    return AppShell(
      title: 'Ayarlar',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Ayarlar',
              icon: Icons.settings_outlined,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kategori seçerek ilgili ayarları görüntüleyin.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= AppBreakpoints.desktop
                    ? 3
                    : width >= AppBreakpoints.tabletLandscape
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: crossAxisCount == 1
                        ? 2.8
                        : crossAxisCount == 2
                            ? 2.1
                            : 1.75,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return SettingsCategoryCard(category: categories[index]);
                  },
                );
              },
            ),
            if (isDoctor) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await appSettingsController.resetToDefaults();
                    final u = AuthSession.currentUser;
                    if (u != null) {
                      AuthSession.updateDisplayName(
                        appSettingsController.displayNameForRole(u.role),
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ayarlar varsayılan değerlere döndürüldü.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Varsayılanlara dön'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
