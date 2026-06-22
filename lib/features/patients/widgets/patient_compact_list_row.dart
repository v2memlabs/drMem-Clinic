import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/clinical_list_row.dart';
import '../data/patient_remote_display.dart';
import '../models/patient.dart';
import '../patient_display_helpers.dart';

/// Desktop/tablet — kompakt tablo-liste satırı (~48–56 px).
class PatientCompactListRow extends StatelessWidget {
  static const double rowHeight = 52;

  final Patient patient;
  final VoidCallback onTap;

  const PatientCompactListRow({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final name = PatientDisplayHelpers.formatListName(patient);
    final allTags = PatientRemoteDisplay.showTags(patient) ? patient.tags : <String>[];
    final visibleTags = allTags.take(2).toList();
    final overflowCount = allTags.length - visibleTags.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.accentTurquoise.withValues(alpha: 0.06),
        child: SizedBox(
          height: rowHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSoft),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 28,
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
                  Expanded(
                    flex: 14,
                    child: Text(
                      patient.fileNumber,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      PatientDisplayHelpers.formatAgeGenderLine(patient),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      PatientDisplayHelpers.formatPhone(patient),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 88,
                    child: Text(
                      PatientDisplayHelpers.formatLastVisit(patient.lastVisitDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 14,
                    child: visibleTags.isEmpty && overflowCount <= 0
                        ? Text(
                            '—',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                          )
                        : Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              for (final t in visibleTags) ClinicalTagChip(label: t),
                              if (overflowCount > 0)
                                ClinicalTagChip(label: '+$overflowCount'),
                            ],
                          ),
                  ),
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(Icons.chevron_right, size: 20),
                    tooltip: 'Detay',
                    visualDensity: VisualDensity.compact,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tablo başlık satırı (desktop).
class PatientCompactListHeader extends StatelessWidget {
  const PatientCompactListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        );

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundSoft,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Expanded(flex: 28, child: Text('Hasta', style: style)),
          Expanded(flex: 14, child: Text('Dosya no', style: style)),
          SizedBox(width: 56, child: Text('Yaş', style: style)),
          Expanded(flex: 16, child: Text('Telefon', style: style)),
          SizedBox(width: 88, child: Text('Son ziyaret', style: style)),
          Expanded(flex: 14, child: Text('Etiket', style: style)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
