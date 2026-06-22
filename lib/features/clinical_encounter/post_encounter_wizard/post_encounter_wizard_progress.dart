import 'package:flutter/material.dart';

import 'models/post_encounter_document_kind.dart';

/// Sihirbaz ilerleme göstergesi.
class PostEncounterWizardProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String? label;

  const PostEncounterWizardProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSteps <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? 'Muayene sonrası adımlar',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Text(
                  '$currentStep / $totalSteps',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}

String postEncounterWizardStepLabel(PostEncounterDocumentKind kind) =>
    kind.label;
