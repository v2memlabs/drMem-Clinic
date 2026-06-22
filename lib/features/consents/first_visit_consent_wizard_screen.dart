import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_snack_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/consent_completion_rules.dart';
import 'data/consent_document_prepare_helper.dart';
import 'data/consent_gate_session_store.dart';
import 'data/consent_list_refresh.dart';
import 'data/consent_list_user_messages.dart';
import 'data/consent_repository_failure.dart';
import 'data/consent_template_resolver.dart';
import 'data/first_visit_consent_checklist.dart';
import 'data/first_visit_consent_gate.dart';
import 'data/first_visit_consent_requirements.dart';
import 'models/consent_record.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/models/patient.dart';

class FirstVisitConsentWizardScreen extends StatefulWidget {
  final String patientId;

  const FirstVisitConsentWizardScreen({super.key, required this.patientId});

  @override
  State<FirstVisitConsentWizardScreen> createState() =>
      _FirstVisitConsentWizardScreenState();
}

class _FirstVisitConsentWizardScreenState
    extends State<FirstVisitConsentWizardScreen> {
  late Future<_WizardLoadResult> _loadFuture;
  int _stepIndex = 0;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture = _load();
    });
  }

  Future<_WizardLoadResult> _load() async {
    final patient = await PatientLookupDataSource.findById(widget.patientId);
    try {
      final checklist =
          await FirstVisitConsentGate.loadChecklist(widget.patientId);
      return _WizardLoadResult(patient: patient, checklist: checklist);
    } on ConsentRepositoryException catch (e) {
      return _WizardLoadResult(
        patient: patient,
        loadError: ConsentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return _WizardLoadResult(
        patient: patient,
        loadError: ConsentListUserMessages.genericLoadFailure,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WizardLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const AppShell(
            title: 'İlk Ziyaret Onamları',
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return AppShell(
            title: 'İlk Ziyaret Onamları',
            child: Center(child: Text(ConsentListUserMessages.genericLoadFailure)),
          );
        }

        if (data.loadError != null) {
          return AppShell(
            title: 'İlk Ziyaret Onamları',
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.loadError!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(onPressed: _reload, child: const Text('Tekrar dene')),
                  ],
                ),
              ),
            ),
          );
        }

        if (data.patient == null) {
          return AppShell(
            title: 'İlk Ziyaret Onamları',
            child: const Center(child: Text('Hasta bulunamadı.')),
          );
        }

        final items = data.checklist!.items;
        if (data.checklist!.isComplete) {
          return _buildCompleteShell(data.patient!);
        }

        final incomplete = data.checklist!.incompleteItems;
        final currentType = incomplete.isNotEmpty
            ? incomplete.first.consentType
            : items[_stepIndex.clamp(0, items.length - 1)].consentType;
        final currentItem = items.firstWhere((i) => i.consentType == currentType);
        final stepNumber =
            FirstVisitConsentRequirements.requiredTypes.indexOf(currentType) + 1;

        return AppShell(
          title: 'İlk Ziyaret Onamları',
          child: ResponsiveDetailPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  title: 'İlk Ziyaret Onam Sihirbazı',
                  icon: Icons.checklist_rtl_outlined,
                  leadingBack: true,
                  fallbackRoute: '/consents',
                ),
                Text(
                  data.patient!.fullName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  value: items.where((i) => i.isComplete).length / items.length,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Adım $stepNumber / ${items.length}: ${consentTypeLabel(currentType)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...items.map((item) => _WizardStepTile(item: item)),
                const SizedBox(height: AppSpacing.md),
                if (currentItem.latestRecord != null &&
                    currentItem.latestRecord!.documentFileName != null &&
                    ConsentCompletionRules.needsSignature(
                      currentItem.latestRecord!,
                    ))
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/consents/${currentItem.latestRecord!.id}',
                    ),
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('Evrakı imzala'),
                  )
                else if (currentItem.isComplete)
                  OutlinedButton.icon(
                    onPressed: () => _advanceStep(items, currentType),
                    icon: const Icon(Icons.arrow_forward_outlined),
                    label: const Text('Sonraki adım'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _creating || !AuthSession.canEditConsents
                        ? null
                        : () => _createDocument(
                              patient: data.patient!,
                              type: currentType,
                            ),
                    icon: _creating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.note_add_outlined),
                    label: Text(
                      _creating ? 'Oluşturuluyor…' : 'Evrak oluştur ve imzala',
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => context.push(
                    '/consents?patientId=${widget.patientId}',
                  ),
                  child: const Text('Onam listesine git'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompleteShell(Patient patient) {
    return AppShell(
      title: 'İlk Ziyaret Onamları',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'İlk Ziyaret Onamları',
              icon: Icons.check_circle_outline,
              leadingBack: true,
              fallbackRoute: '/consents',
            ),
            Text(
              '${patient.fullName} için zorunlu onam evrakları tamamlandı.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }

  void _advanceStep(
    List<FirstVisitConsentChecklistItem> items,
    ConsentType currentType,
  ) {
    final idx = FirstVisitConsentRequirements.requiredTypes.indexOf(currentType);
    if (idx < items.length - 1) {
      setState(() => _stepIndex = idx + 1);
    }
    _reload();
  }

  Future<void> _createDocument({
    required Patient patient,
    required ConsentType type,
  }) async {
    final template =
        await ConsentTemplateResolver.resolveActiveTemplateAsync(type);
    if (template == null) {
      showClinicalSnackBar(
        context,
        'Bu onam tipi için aktif şablon bulunamadı.',
        isError: true,
      );
      return;
    }

    final remoteError = ConsentDocumentPrepareHelper.validateRemoteReady();
    if (remoteError != null) {
      showClinicalSnackBar(context, remoteError, isError: true);
      return;
    }

    final recordedBy =
        AuthSession.currentUser?.displayName ?? 'Kullanıcı';

    setState(() => _creating = true);
    try {
      final result = await ConsentDocumentPrepareHelper.saveGeneratedDocument(
        template: template,
        patient: patient,
        consent: ConsentRecord(
          id: '',
          patientId: patient.id,
          patientName: patient.fullName,
          createdAt: DateTime.now(),
          consentType: type,
          status: ConsentStatus.bekliyor,
          recordedBy: recordedBy,
          notes: 'Şablon: ${template.title} (${template.version})',
        ),
        recordedBy: recordedBy,
        preparedAt: DateTime.now(),
      );

      if (!mounted) return;

      if (!result.success) {
        showClinicalSnackBar(
          context,
          result.errorMessage ?? 'Evrak oluşturulamadı.',
          isError: true,
        );
        return;
      }

      ConsentGateSessionStore.clearDismiss(widget.patientId);
      ConsentListRefresh.markStale();
      _reload();
      if (!mounted) return;

      final refreshed = await FirstVisitConsentGate.loadChecklist(widget.patientId);
      final item = refreshed.items.firstWhere((i) => i.consentType == type);
      final recordId = item.latestRecord?.id;
      if (recordId != null) {
        await context.push('/consents/$recordId');
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }
}

class _WizardLoadResult {
  final Patient? patient;
  final FirstVisitConsentChecklist? checklist;
  final String? loadError;

  const _WizardLoadResult({
    required this.patient,
    this.checklist,
    this.loadError,
  });
}

class _WizardStepTile extends StatelessWidget {
  final FirstVisitConsentChecklistItem item;

  const _WizardStepTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = item.latestRecord;
    String statusLabel;
    IconData icon;
    Color color;

    if (item.isComplete) {
      statusLabel = 'Alındı';
      icon = Icons.check_circle_outline;
      color = theme.colorScheme.primary;
    } else if (record != null &&
        record.status == ConsentStatus.alindi &&
        ConsentCompletionRules.needsSignature(record)) {
      statusLabel = 'İmza bekliyor';
      icon = Icons.draw_outlined;
      color = theme.colorScheme.tertiary;
    } else if (record != null && record.documentFileName != null) {
      statusLabel = 'İmza bekliyor';
      icon = Icons.draw_outlined;
      color = theme.colorScheme.tertiary;
    } else {
      statusLabel = 'Eksik';
      icon = Icons.radio_button_unchecked;
      color = theme.colorScheme.onSurfaceVariant;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(item.label),
      trailing: Text(
        statusLabel,
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
