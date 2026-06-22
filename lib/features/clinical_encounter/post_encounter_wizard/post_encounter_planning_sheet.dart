import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_spacing.dart';
import 'models/post_encounter_document_kind.dart';

/// Muayene kaydı sonrası — hangi belgelerin oluşturulacağını seçme sayfası.
class PostEncounterPlanningSelection {
  final Set<PostEncounterDocumentKind> selected;

  const PostEncounterPlanningSelection(this.selected);

  List<PostEncounterDocumentKind> get orderedSteps {
    const order = PostEncounterDocumentKind.values;
    return order.where(selected.contains).toList(growable: false);
  }
}

Future<PostEncounterPlanningSelection?> showPostEncounterPlanningSheet(
  BuildContext context,
) {
  return showModalBottomSheet<PostEncounterPlanningSelection>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: true,
    builder: (context) => const _PostEncounterPlanningSheet(),
  );
}

class _PostEncounterPlanningSheet extends StatefulWidget {
  const _PostEncounterPlanningSheet();

  @override
  State<_PostEncounterPlanningSheet> createState() =>
      _PostEncounterPlanningSheetState();
}

class _PostEncounterPlanningSheetState extends State<_PostEncounterPlanningSheet> {
  final _selected = <PostEncounterDocumentKind>{};

  bool _canSelect(PostEncounterDocumentKind kind) {
    return switch (kind) {
      PostEncounterDocumentKind.lab => AuthSession.canEditLabOrders,
      PostEncounterDocumentKind.radiology => AuthSession.canEditRadiologyOrders,
      PostEncounterDocumentKind.prescription =>
        AuthSession.canEditPrescriptions,
      PostEncounterDocumentKind.clinicalReport =>
        AuthSession.canEditClinicalReports,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledKinds =
        PostEncounterDocumentKind.values.where(_canSelect).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Muayene sonrası adımlar',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Oluşturmak istediğiniz belgeleri seçin. Ödeme adımı her zaman açılır.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (enabledKinds.isEmpty)
              Text(
                'Bu oturumda oluşturabileceğiniz belge türü yok; ödeme adımına geçebilirsiniz.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...enabledKinds.map(
                (kind) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(kind.label),
                  value: _selected.contains(kind),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(kind);
                      } else {
                        _selected.remove(kind);
                      }
                    });
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(
                      const PostEncounterPlanningSelection({}),
                    ),
                    child: const Text('Atla'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      PostEncounterPlanningSelection(Set.of(_selected)),
                    ),
                    child: const Text('Devam'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
