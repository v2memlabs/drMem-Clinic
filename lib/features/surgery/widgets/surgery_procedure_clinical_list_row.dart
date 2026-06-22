import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../patients/patient_display_helpers.dart';
import '../../../shared/widgets/premium_surface.dart';
import '../data/surgery_procedure_list_display.dart';
import '../models/surgery_procedure_note.dart';

class SurgeryProcedureClinicalListRow extends StatelessWidget {
  final SurgeryProcedureNote note;
  final VoidCallback onTap;

  const SurgeryProcedureClinicalListRow({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentRailColor =
        SurgeryProcedureListDisplay.markerColorForType(note.procedureType);
    final dateLabel =
        SurgeryProcedureListDisplay.formatProcedureDate(note.procedureDate);
    final detailLine = SurgeryProcedureListDisplay.detailLine(
      procedureName: note.procedureName,
      surgeonName: note.surgeonName,
    );

    final name = note.patientName.trim().isEmpty
        ? PatientDisplayHelpers.unnamedPatient
        : note.patientName.trim();
    final meta = SurgeryProcedureListDisplay.metaLine(
      fileNumber: null,
      diagnosis: note.diagnosis,
    );

    return _SurgeryProcedureListCard(
      name: name,
      meta: meta,
      detailLine: detailLine,
      dateLabel: dateLabel,
      accentRailColor: accentRailColor,
      onTap: onTap,
    );
  }
}

class _SurgeryProcedureListCard extends StatelessWidget {
  final String name;
  final String? meta;
  final String detailLine;
  final String dateLabel;
  final Color accentRailColor;
  final VoidCallback onTap;

  const _SurgeryProcedureListCard({
    required this.name,
    this.meta,
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
                                  if (meta != null && meta!.isNotEmpty) ...[
                                    Text(
                                      ' · ',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        meta!,
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
