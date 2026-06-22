import 'package:flutter/material.dart';



import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_radius.dart';

import '../../../core/theme/app_shadows.dart';

import '../../../core/theme/app_spacing.dart';

import '../../../shared/layout/app_breakpoints.dart';
import '../../../shared/widgets/data_list_card.dart';

import '../data/patient_identity_privacy.dart';
import '../data/patient_remote_display.dart';
import '../models/patient.dart';



/// Hasta listesi / detay premium kart yüzeyleri.

abstract final class PatientPremiumSurfaces {

  static const double listMaxWidth = AppBreakpoints.listMaxWidth;

  static const double detailMaxWidth = AppBreakpoints.detailMaxWidth;



  static BoxDecoration card({bool subtle = true}) => BoxDecoration(

        color: AppColors.surfaceCard,

        borderRadius: AppRadius.cardBorder,

        border: Border.all(color: AppColors.borderSoft),

        boxShadow: subtle ? null : AppShadows.card,

      );



  /// Dosya kartı üst vurgusu — sol turkuaz şerit.

  static BoxDecoration dossierHeader() => BoxDecoration(

        color: AppColors.surfaceCard,

        borderRadius: AppRadius.cardBorder,

        border: Border.all(color: AppColors.borderSoft),

        boxShadow: AppShadows.subtle,

      );



  static Widget sectionHeader(

    BuildContext context, {

    required String title,

    String? subtitle,

    Widget? trailing,

    IconData? icon,

  }) {

    return Padding(

      padding: const EdgeInsets.only(left: AppSpacing.xxs, bottom: AppSpacing.sm),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.end,

        children: [

          if (icon != null) ...[

            iconBadge(icon, size: 36),

            const SizedBox(width: AppSpacing.sm),

          ],

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: Theme.of(context).textTheme.titleSmall?.copyWith(

                        fontWeight: FontWeight.w600,

                        color: AppColors.primaryDeepTeal,

                      ),

                ),

                if (subtitle != null && subtitle.isNotEmpty) ...[

                  const SizedBox(height: AppSpacing.xxs),

                  Text(

                    subtitle,

                    style: Theme.of(context).textTheme.bodySmall?.copyWith(

                          color: AppColors.textSecondary,

                        ),

                  ),

                ],

              ],

            ),

          ),

          if (trailing != null) trailing,

        ],

      ),

    );

  }



  static Widget iconBadge(IconData icon, {Color? accent, double size = 44}) {

    final color = accent ?? AppColors.accentTurquoise;

    return Container(

      width: size,

      height: size,

      decoration: BoxDecoration(

        color: color.withValues(alpha: 0.12),

        borderRadius: AppRadius.mediumBorder,

        border: Border.all(color: color.withValues(alpha: 0.3)),

      ),

      child: Icon(icon, size: size * 0.5, color: color),

    );

  }



  static Widget metaChip(String label) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),

      decoration: BoxDecoration(

        color: AppColors.backgroundSoft,

        borderRadius: AppRadius.smallBorder,

        border: Border.all(color: AppColors.borderSoft),

      ),

      child: Text(

        label,

        style: const TextStyle(

          fontSize: 11,

          fontWeight: FontWeight.w500,

          color: AppColors.textSecondary,

        ),

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

      ),

    );

  }



  /// Rehab / klinik alt blok kartı.

  static Widget nestedBlock({required Widget child}) {

    return Container(

      width: double.infinity,

      margin: const EdgeInsets.only(bottom: AppSpacing.sm),

      padding: const EdgeInsets.all(AppSpacing.sm),

      decoration: card(subtle: true),

      child: child,

    );

  }



  /// Detay ekranı aksiyon buton grubu.

  static Widget actionsBar({required Widget child}) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(AppSpacing.sm),

      decoration: BoxDecoration(

        color: AppColors.backgroundSoft,

        borderRadius: AppRadius.mediumBorder,

        border: Border.all(color: AppColors.borderSoft),

      ),

      child: child,

    );

  }



  /// Liste boş durumu — premium kart içinde.

  static Widget listEmptyState({

    required IconData icon,

    required String title,

    required String description,

  }) {

    return Container(

      decoration: card(subtle: true),

      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),

      child: Center(

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Icon(icon, size: 48, color: AppColors.textSecondary),

            const SizedBox(height: AppSpacing.sm),

            Text(

              title,

              style: const TextStyle(

                fontSize: 16,

                fontWeight: FontWeight.w600,

                color: AppColors.textPrimary,

              ),

              textAlign: TextAlign.center,

            ),

            const SizedBox(height: AppSpacing.xs),

            Text(

              description,

              style: const TextStyle(

                fontSize: 13,

                color: AppColors.textSecondary,

              ),

              textAlign: TextAlign.center,

            ),

          ],

        ),

      ),

    );

  }

}



/// Hasta listesi satır kartı — net bilgi hiyerarşisi.

class PatientListCard extends StatelessWidget {

  final Patient patient;

  final VoidCallback onTap;



  const PatientListCard({

    super.key,

    required this.patient,

    required this.onTap,

  });



  @override

  Widget build(BuildContext context) {

    final identityShort =
        PatientIdentityPrivacy.formatIdentityLineForDisplay(patient);



    final metaParts = <String>[];
    if (PatientRemoteDisplay.showPhone(patient)) {
      metaParts.add(patient.phone);
    }
    if (identityShort != null) metaParts.add(identityShort);
    metaParts.add('${patient.age} yaş');
    final metaLine = metaParts.join(' • ');

    final chips = <String>[
      if (PatientRemoteDisplay.showNationality(patient)) patient.nationality,
      if (PatientRemoteDisplay.showInsurance(patient)) patient.insuranceType,
      if (PatientRemoteDisplay.showTags(patient)) ...patient.tags.take(4),
    ];

    final complaint = patient.primaryComplaint.trim();
    final region = patient.bodyRegion.trim();
    final contextLine = [
      if (PatientRemoteDisplay.showComplaint(patient)) complaint,
      if (PatientRemoteDisplay.showBodyRegion(patient)) region,
    ].join(' • ');



    return DataListCard(

      title: patient.fullName,

      subtitle: 'Dosya ${patient.fileNumber}',

      metaLine: metaLine,

      trailing: _formatVisitDate(patient.lastVisitDate),

      chips: chips,

      contextLine: contextLine.isEmpty ? null : contextLine,

      onTap: onTap,

    );

  }



  static String _formatVisitDate(DateTime date) {

    final local = date.toLocal();

    final d = local.day.toString().padLeft(2, '0');

    final m = local.month.toString().padLeft(2, '0');

    return 'Son başvuru $d.$m.${local.year}';

  }

}


