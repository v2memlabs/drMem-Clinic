import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/patients/models/patient_timeline_event.dart';
import 'premium_surface.dart';
import 'status_chip.dart';

/// Hasta timeline olay kartı — klinik akış hissi.
class TimelineEventCard extends StatelessWidget {
  final PatientTimelineEvent event;
  final bool showPatientName;
  final VoidCallback? onTap;

  const TimelineEventCard({
    super.key,
    required this.event,
    this.showPatientName = false,
    this.onTap,
  });

  String get _dateTimeLabel {
    final local = event.eventDate.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$d.$m.${local.year} $time';
  }

  IconData get _eventIcon => StatusChip.iconForTimeline(event.eventType);

  @override
  Widget build(BuildContext context) {
    final headline = showPatientName ? event.patientName : event.title;
    final subline = showPatientName ? event.title : event.description;
    final contextLine = showPatientName
        ? event.description
        : (event.createdBy != 'Belirtilmedi' ? 'Kaydeden: ${event.createdBy}' : null);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: AppColors.accentTurquoise.withValues(alpha: 0.06),
        child: DecoratedBox(
          decoration: PremiumSurface.card(elevated: false),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumSurface.iconBadge(
                  icon: _eventIcon,
                  accent: AppColors.accentTurquoise,
                  compact: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              headline,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDeepTeal,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _dateTimeLabel,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      if (subline.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subline,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (contextLine != null && contextLine!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          contextLine!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          StatusChip.timelineEvent(event.eventType),
                          StatusChip(
                            label: event.relatedModule,
                            tone: StatusChipTone.neutral,
                            icon: Icons.folder_open_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
