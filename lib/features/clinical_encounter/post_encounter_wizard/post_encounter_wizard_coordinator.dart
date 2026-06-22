import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../models/clinical_encounter.dart';
import 'models/post_encounter_wizard_step_result.dart';
import 'post_encounter_planning_sheet.dart';
import 'post_encounter_print_service.dart';
import 'post_encounter_wizard_navigation.dart';

/// Yeni muayene kaydı sonrası belge + ödeme akışını yönetir.
abstract final class PostEncounterWizardCoordinator {
  static Future<void> start(
    BuildContext context,
    ClinicalEncounter encounter,
  ) async {
    if (!context.mounted) return;

    final planning = await showPostEncounterPlanningSheet(context);
    if (!context.mounted) return;
    if (planning == null) {
      _finish(context);
      return;
    }

    final documentSteps = planning.orderedSteps;
    final includePaymentStep =
        TenantFinancialFeatureGate.encounterPaymentStepEnabled &&
            AuthSession.canEditPayments;
    final totalSteps = documentSteps.length + (includePaymentStep ? 1 : 0);

    for (final kind in documentSteps) {
      if (!context.mounted) return;

      final path = PostEncounterWizardNavigation.buildDocumentFormPath(
        kind: kind,
        patientId: encounter.patientId,
        clinicalEncounterId: encounter.id,
      );

      final result = await context.push<PostEncounterWizardStepResult>(path);
      if (!context.mounted) return;

      if (result != null) {
        final shouldPrint = await showPostEncounterPrintPrompt(
          context,
          kind: kind,
        );
        if (!context.mounted) return;

        if (shouldPrint) {
          try {
            await PostEncounterPrintService.printDocument(
              kind: kind,
              documentId: result.documentId,
            );
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PDF yazdırılırken bir sorun oluştu.'),
                ),
              );
            }
          }
        }
      }
    }

    if (!context.mounted) return;

    if (includePaymentStep) {
      final paymentPath =
          '${PostEncounterWizardNavigation.buildPaymentStepPath(encounter.id)}'
          '?step=$totalSteps&total=$totalSteps';

      await context.push<void>(paymentPath);
      if (!context.mounted) return;
    }

    if (!context.mounted) return;
    if (encounter.physiotherapyReferral &&
        AuthSession.canEditClinicalEncounters) {
      context.go(
        '/physiotherapy/referrals/new?patientId=${encounter.patientId}'
        '&clinicalEncounterId=${encounter.id}',
      );
      return;
    }

    _finish(context);
  }

  static void _finish(BuildContext context) {
    context.go(AuthSession.dashboardRoute);
  }
}
