import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Supabase bootstrap sırasında kısa yükleme (mock’ta redirect edilmez).
class SessionInitializingScreen extends StatelessWidget {
  const SessionInitializingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator.adaptive(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Oturum hazırlanıyor…',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryDeepTeal,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Profil ve klinik erişimi doğrulanıyor.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
