import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'app_shell.dart';
import 'premium_surface.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String message;

  const AccessDeniedScreen({super.key, required this.message});

  static const String _defaultTitle = 'Bu alana erişim yetkiniz yok';
  static const String _defaultDescription =
      'Bu ekran için gerekli yetki rolünüze tanımlı değil.';

  @override
  Widget build(BuildContext context) {
    final trimmed = message.trim();
    final description = trimmed.isEmpty || trimmed == _defaultTitle
        ? _defaultDescription
        : trimmed;

    return AppShell(
      title: 'Erişim Yok',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: AppRadius.cardBorder,
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: AppShadows.card,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceCard,
                    AppColors.navyDark.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumSurface.iconBadge(
                      icon: Icons.lock_outline_rounded,
                      size: 48,
                      accent: AppColors.navy,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _defaultTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDeepTeal,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go(AuthSession.dashboardRoute),
                        icon: const Icon(Icons.home_outlined, size: 18),
                        label: const Text('Ana Ekran\'a Dön'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
