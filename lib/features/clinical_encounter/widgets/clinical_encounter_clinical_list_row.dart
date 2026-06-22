import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../patients/patient_display_helpers.dart';
import '../../../shared/widgets/clinical_list_status_tones.dart';
import '../../../shared/widgets/premium_surface.dart';
import '../data/clinical_encounter_list_display.dart';
import '../models/clinical_encounter.dart';

class ClinicalEncounterClinicalListRow extends StatelessWidget {
  final ClinicalEncounter encounter;
  final bool usesRemote;
  final VoidCallback onTap;

  const ClinicalEncounterClinicalListRow({
    super.key,
    required this.encounter,
    required this.usesRemote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusTone =
        ClinicalListStatusTones.clinicalEncounterStatus(encounter.status);
    final accentRailColor =
        ClinicalListStatusTones.markerColorForTone(statusTone) ??
            AppColors.borderSoft;
    final dateLabel = ClinicalEncounterListDisplay.formatEncounterDate(
      encounter.createdAt,
    );
    final detailLine = ClinicalEncounterListDisplay.listDetailLine(
      encounter,
      usesRemote: usesRemote,
    );

    final name = encounter.patientName.trim().isEmpty
        ? PatientDisplayHelpers.unnamedPatient
        : encounter.patientName.trim();

    return _ClinicalEncounterListCard(
      name: name,
      demographic: null,
      detailLine: detailLine,
      dateLabel: dateLabel,
      accentRailColor: accentRailColor,
      onTap: onTap,
    );
  }
}

class _ClinicalEncounterListCard extends StatelessWidget {
  final String name;
  final String? demographic;
  final String detailLine;
  final String dateLabel;
  final Color accentRailColor;
  final VoidCallback onTap;

  const _ClinicalEncounterListCard({
    required this.name,
    this.demographic,
    required this.detailLine,
    required this.dateLabel,
    required this.accentRailColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
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
                                        color: AppColors.primaryDeepTeal,
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
                              dateLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.accentTurquoise,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          detailLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
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
  }
}
