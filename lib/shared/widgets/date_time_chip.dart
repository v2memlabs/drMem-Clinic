import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Tarih/saat gösterimi — nötr pill, gradient yok.
class DateTimeChip extends StatelessWidget {
  final DateTime dateTime;
  final bool showIcon;
  final VoidCallback? onTap;

  const DateTimeChip({
    super.key,
    required this.dateTime,
    this.showIcon = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettingsController,
      builder: (context, _) {
        final formatted = AppSettings.formatDateTime(
          dateTime,
          appSettingsController.settings.dateTimeFormat,
          timeFormat: appSettingsController.settings.timeFormat,
        );
        final chip = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundSoft,
            borderRadius: AppRadius.mediumBorder,
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  Icons.calendar_month_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                formatted,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        );

        if (onTap == null) return chip;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.mediumBorder,
            child: chip,
          ),
        );
      },
    );
  }
}
