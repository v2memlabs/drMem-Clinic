import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/premium_surface.dart';
import '../data/appointment_remote_display.dart';
import '../models/appointment.dart';

class AppointmentClinicalListRow extends StatelessWidget {
  final Appointment appointment;
  final bool usesRemote;
  final VoidCallback onTap;

  const AppointmentClinicalListRow({
    super.key,
    required this.appointment,
    required this.usesRemote,
    required this.onTap,
  });

  static bool isDimmedStatus(AppointmentStatus status) =>
      status == AppointmentStatus.iptal ||
      status == AppointmentStatus.ertelendi;

  @override
  Widget build(BuildContext context) {
    final tone = ClinicalListStatusTones.appointmentStatus(appointment.status);
    final marker = ClinicalListStatusTones.markerColorForTone(tone);
    final dimmed = isDimmedStatus(appointment.status);

    final name = AppointmentRemoteDisplay.patientDisplayName(
      appointment.patientName,
    );
    final fileNumber = appointment.patientFileNumber?.trim();

    return ListenableBuilder(
      listenable: appSettingsController,
      builder: (context, _) {
        final timeLabel = AppSettings.formatTime(
          appointment.appointmentDateTime.toLocal(),
          appSettingsController.settings.dateTimeFormat,
          timeFormat: appSettingsController.settings.timeFormat,
        );

        return _AppointmentListCard(
          name: name,
          demographic:
              fileNumber != null && fileNumber.isNotEmpty ? fileNumber : null,
          typeLabel: appointmentTypeLabel(appointment.type),
          timeLabel: timeLabel,
          accentRailColor: marker ?? AppColors.borderSoft,
          dimmed: dimmed,
          onTap: onTap,
        );
      },
    );
  }
}

class _AppointmentListCard extends StatelessWidget {
  final String name;
  final String? demographic;
  final String typeLabel;
  final String timeLabel;
  final Color accentRailColor;
  final bool dimmed;
  final VoidCallback onTap;

  const _AppointmentListCard({
    required this.name,
    this.demographic,
    required this.typeLabel,
    required this.timeLabel,
    required this.accentRailColor,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor =
        dimmed ? AppColors.textSecondary : AppColors.primaryDeepTeal;

    Widget body = Material(
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
          decoration: PremiumSurface.card(elevated: true),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: PremiumSurface.listAccentRail(
                    color: accentRailColor,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Text(
                                      name,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: titleColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (demographic != null &&
                                      demographic!.isNotEmpty) ...[
                                    Text(
                                      ' · ',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        demographic!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              timeLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: dimmed
                                    ? AppColors.textSecondary
                                    : AppColors.accentTurquoise,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          typeLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (dimmed) {
      body = Opacity(opacity: 0.62, child: body);
    }

    return body;
  }
}
