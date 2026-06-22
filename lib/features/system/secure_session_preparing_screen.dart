import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Cold-start oturum purge tamamlanana kadar gösterilir.
class SecureSessionPreparingScreen extends StatelessWidget {
  const SecureSessionPreparingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator.adaptive(),
              SizedBox(height: AppSpacing.md),
              Text(
                'Güvenli oturum hazırlanıyor…',
                style: TextStyle(
                  color: AppColors.primaryDeepTeal,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
