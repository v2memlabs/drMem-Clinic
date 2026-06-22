import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../payments/widgets/patient_material_charge_launcher.dart';
import '../widgets/patient_premium_surfaces.dart';
import 'patient_detail_action_context.dart';
import 'patient_detail_action_registry.dart';
import 'patient_detail_section_card.dart';

class PatientDetailActionList extends StatelessWidget {
  final PatientDetailActionContext actionContext;
  final List<PatientDetailAction> actions;

  const PatientDetailActionList({
    super.key,
    required this.actionContext,
    required this.actions,
  });

  @override
  Widget build(BuildContext buildContext) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return PatientDetailSectionCard(
      title: PatientDetailActionRegistry.listTitle,
      child: Column(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 48,
                color: AppColors.borderSoft,
              ),
            _PatientDetailActionRow(
              action: actions[i],
              actionContext: actionContext,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact trailing buttons for section card headers.
class PatientDetailCardTrailingBar extends StatelessWidget {
  final PatientDetailActionContext actionContext;
  final List<PatientDetailAction> actions;

  const PatientDetailCardTrailingBar({
    super.key,
    required this.actionContext,
    required this.actions,
  });

  @override
  Widget build(BuildContext navigationContext) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      alignment: WrapAlignment.end,
      children: [
        for (final action in actions)
          TextButton(
            onPressed: () {
              if (action.launchesMaterialCharge) {
                PatientMaterialChargeLauncher.launch(
                  navigationContext,
                  patientId: actionContext.patientId,
                );
              } else {
                action.invoke(navigationContext, actionContext);
              }
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(action.label),
          ),
      ],
    );
  }
}

class _PatientDetailActionRow extends StatelessWidget {
  final PatientDetailAction action;
  final PatientDetailActionContext actionContext;

  const _PatientDetailActionRow({
    required this.action,
    required this.actionContext,
  });

  @override
  Widget build(BuildContext buildContext) {
    return InkWell(
      onTap: () {
        if (action.launchesMaterialCharge) {
          PatientMaterialChargeLauncher.launch(
            buildContext,
            patientId: actionContext.patientId,
          );
        } else {
          action.invoke(buildContext, actionContext);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            PatientPremiumSurfaces.iconBadge(action.icon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                action.label,
                style: Theme.of(buildContext).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
