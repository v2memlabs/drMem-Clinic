import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/consent_gate_session_store.dart';
import '../data/consent_completion_rules.dart';
import '../data/first_visit_consent_checklist.dart';
import '../data/first_visit_consent_gate.dart';

/// Detay ekranı yüklendikten sonra zorunlu onam uyarısını gösterir.
abstract final class ConsentGatePresenter {
  static Future<void> showIfNeeded(
    BuildContext context, {
    required String patientId,
  }) async {
    if (!AuthSession.canViewConsents) return;

    final pid = patientId.trim();
    if (pid.isEmpty) return;
    if (ConsentGateSessionStore.isDismissed(pid)) return;

    final checklist = await FirstVisitConsentGate.loadChecklist(pid);
    if (checklist.isComplete) {
      ConsentGateSessionStore.clearDismiss(pid);
      return;
    }
    if (!context.mounted) return;

    await showConsentGateModal(
      context,
      checklist: checklist,
      patientId: pid,
    );
  }
}

Future<void> showConsentGateModal(
  BuildContext context, {
  required FirstVisitConsentChecklist checklist,
  required String patientId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      return ConsentGateSheet(
        checklist: checklist,
        patientId: patientId,
      );
    },
  );
}

class ConsentGateSheet extends StatelessWidget {
  final FirstVisitConsentChecklist checklist;
  final String patientId;

  const ConsentGateSheet({
    super.key,
    required this.checklist,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final incomplete = checklist.incompleteItems;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_late_outlined,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'İlk ziyaret onam evrakları eksik',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hasta kaydı, randevu veya muayene sürecine devam etmeden önce '
            'aşağıdaki onam evraklarının tamamlanması önerilir.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...checklist.items.map(
            (item) => _ChecklistRow(item: item),
          ),
          if (incomplete.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${incomplete.length} evrak eksik',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/consents/first-visit-wizard?patientId=$patientId');
            },
            icon: const Icon(Icons.checklist_rtl_outlined),
            label: const Text('Onam sihirbazını başlat'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/consents?patientId=$patientId');
            },
            child: const Text('Onam listesine git'),
          ),
          TextButton(
            onPressed: () {
              ConsentGateSessionStore.dismiss(patientId);
              Navigator.of(context).pop();
            },
            child: const Text('Devam et'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final FirstVisitConsentChecklistItem item;

  const _ChecklistRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = item.latestRecord;
    String trailing;
    IconData icon;
    Color color;

    if (item.isComplete) {
      trailing = 'Alındı';
      icon = Icons.check_circle_outline;
      color = theme.colorScheme.primary;
    } else if (record != null && ConsentCompletionRules.needsSignature(record)) {
      trailing = 'İmza bekliyor';
      icon = Icons.draw_outlined;
      color = theme.colorScheme.tertiary;
    } else if (record != null && record.documentFileName != null) {
      trailing = 'İmza bekliyor';
      icon = Icons.draw_outlined;
      color = theme.colorScheme.tertiary;
    } else {
      trailing = 'Eksik';
      icon = Icons.radio_button_unchecked;
      color = theme.colorScheme.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            trailing,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Detay ekranı yüklendiğinde onam gate kontrolü yapar.
class ConsentGateScope extends StatefulWidget {
  final String patientId;
  final Widget child;

  const ConsentGateScope({
    super.key,
    required this.patientId,
    required this.child,
  });

  @override
  State<ConsentGateScope> createState() => _ConsentGateScopeState();
}

class _ConsentGateScopeState extends State<ConsentGateScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConsentGatePresenter.showIfNeeded(
        context,
        patientId: widget.patientId,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
