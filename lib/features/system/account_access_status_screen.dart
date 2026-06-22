import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/auth_route_guard.dart';
import '../../core/session/auth_session_lifecycle.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/premium_surface.dart';
import '../../core/session/account_access_reason.dart';

/// Membership / tenant erişim engeli (Supabase fazı; mock’ta redirect edilmez).
class AccountAccessStatusScreen extends StatelessWidget {
  final AccountAccessReason reason;

  const AccountAccessStatusScreen({
    super.key,
    this.reason = AccountAccessReason.generic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: SafeArea(
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
                  boxShadow: AppShadows.elevatedCard,
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
                        icon: Icons.domain_disabled_outlined,
                        size: 48,
                        accent: AppColors.navy,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        reason.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDeepTeal,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        reason.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => AuthSessionLifecycle.signOut(context: context),
                          child: const Text('Çıkış Yap'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go(AuthRouteGuard.loginPath),
                          child: const Text('Giriş ekranına dön'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
