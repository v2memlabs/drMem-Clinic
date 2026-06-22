import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinical_list_row.dart';
import '../data/patient_remote_display.dart';
import '../models/patient.dart';
import '../patient_display_helpers.dart';

/// Mobil — 2–3 satırlı kompakt hasta kartı.
class PatientCompactCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientCompactCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final name = PatientDisplayHelpers.formatListName(patient);
    final allTags = PatientRemoteDisplay.showTags(patient) ? patient.tags : <String>[];
    final visibleTags = allTags.take(3).toList();
    final overflowCount = allTags.length - visibleTags.length;

    final line2Parts = <String>[
      PatientDisplayHelpers.formatAgeGenderLine(patient),
      PatientDisplayHelpers.formatPhone(patient),
      PatientDisplayHelpers.formatLastVisit(patient.lastVisitDate),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.accentTurquoise.withValues(alpha: 0.06),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderSoft),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      patient.fileNumber,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  line2Parts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (visibleTags.isNotEmpty || overflowCount > 0) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final t in visibleTags) ClinicalTagChip(label: t),
                      if (overflowCount > 0)
                        ClinicalTagChip(label: '+$overflowCount etiket'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
