import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/post_encounter_document_kind.dart';
import 'models/post_encounter_wizard_step_result.dart';

void navigateAfterDocumentSave(
  BuildContext context, {
  required bool encounterWizardMode,
  required PostEncounterDocumentKind kind,
  required String documentId,
  required String detailPath,
}) {
  if (encounterWizardMode) {
    context.pop(
      PostEncounterWizardStepResult(
        kind: kind,
        documentId: documentId,
      ),
    );
    return;
  }
  context.go(detailPath);
}
