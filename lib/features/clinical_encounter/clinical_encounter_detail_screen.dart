import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/detail_action_labels.dart';
import '../../shared/widgets/detail_actions_panel.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../consents/widgets/consent_gate_modal.dart';
import '../pdf_outputs/contextual_pdf_actions.dart';
import 'data/clinical_encounter_diagnosis_display.dart';
import 'data/clinical_encounter_detail_data_source.dart';
import 'data/clinical_encounter_repository_provider.dart';
import 'data/clinical_encounter_detail_display.dart';
import 'data/clinical_encounter_detail_sections.dart';
import 'data/clinical_encounter_list_refresh.dart';
import 'widgets/clinical_encounter_detail_section.dart';
import 'widgets/clinical_encounter_identity_band.dart';
import 'data/clinical_encounter_detail_load_result.dart';
import 'data/clinical_encounter_detail_user_messages.dart';
import 'models/clinical_encounter.dart';

class ClinicalEncounterDetailScreen extends StatefulWidget {
  final String id;

  const ClinicalEncounterDetailScreen({super.key, required this.id});

  @override
  State<ClinicalEncounterDetailScreen> createState() =>
      _ClinicalEncounterDetailScreenState();
}

class _ClinicalEncounterDetailScreenState
    extends State<ClinicalEncounterDetailScreen> {
  late Future<ClinicalEncounterDetailLoadResult> _loadFuture;
  ClinicalEncounterDetailLoadResult? _cachedResult;
  bool _activatedOnce = false;

  bool get _usesRemote => RepositoryRegistry.usesRemoteClinicalEncounters;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture = ClinicalEncounterDetailDataSource.loadById(widget.id);
    });
  }

  void _retryLoad() {
    ClinicalEncounterRepositoryProvider.resetCache();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClinicalEncounterDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (result != null &&
            !result.hasError &&
            result.encounter != null) {
          _cachedResult = result;
        }

        if (waiting && _cachedResult == null) {
          return AppShell(
            title: 'Muayene Kaydı',
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator.adaptive(),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      ClinicalEncounterDetailUserMessages.loading,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError && _cachedResult == null) {
          return _statusShell(
            title: 'Muayene detayı yüklenemedi',
            message: ClinicalEncounterDetailUserMessages.genericLoadFailure,
            showRetry: true,
          );
        }

        if (result == null && _cachedResult == null) {
          return _statusShell(
            title: 'Muayene detayı yüklenemedi',
            message: ClinicalEncounterDetailUserMessages.genericLoadFailure,
            showRetry: true,
          );
        }

        final active = result ?? _cachedResult!;
        if (active.hasError && _cachedResult == null) {
          return _statusShell(
            title: 'Muayene detayı yüklenemedi',
            message: active.errorMessage,
            showRetry: true,
          );
        }

        if (active.hasError && result != null) {
          return _statusShell(
            title: 'Muayene detayı yüklenemedi',
            message: active.errorMessage,
            showRetry: true,
            showRefreshBar: waiting,
          );
        }

        if (active.encounter == null) {
          return AppShell(
            title: 'Muayene Kaydı',
            child: ClinicalStateMessage.empty(
              icon: Icons.assignment_outlined,
              title: ClinicalEncounterDetailUserMessages.notFound,
              description: 'Kayıt bulunamadı veya erişim yok.',
            ),
          );
        }

        return _ClinicalEncounterDetailLoadedView(
          encounter: active.encounter!,
          encounterId: widget.id,
          usesRemote: _usesRemote,
          refreshing: waiting,
          onEditComplete: _reload,
        );
      },
    );
  }

  Widget _statusShell({
    required String title,
    required String? message,
    required bool showRetry,
    bool showRefreshBar = false,
  }) {
    return AppShell(
      title: 'Muayene Kaydı',
      child: Column(
        children: [
          if (showRefreshBar) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: title,
              description: ClinicalStateMessage.safeErrorDescription(message),
              onRetry: showRetry ? _retryLoad : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalEncounterDetailLoadedView extends StatelessWidget {
  final ClinicalEncounter encounter;
  final String encounterId;
  final bool usesRemote;
  final bool refreshing;
  final VoidCallback onEditComplete;

  const _ClinicalEncounterDetailLoadedView({
    required this.encounter,
    required this.encounterId,
    required this.usesRemote,
    required this.refreshing,
    required this.onEditComplete,
  });

  @override
  Widget build(BuildContext context) {
    final e = encounter;
    final canEdit = AuthSession.canEditClinicalEncounters;
    final internalRows = ClinicalEncounterDetailDisplay.internalNoteRows(
      e,
      usesRemote: usesRemote,
    );

    return ConsentGateScope(
      patientId: e.patientId,
      child: AppShell(
        title: 'Muayene Kaydı',
        child: Column(
          children: [
            if (refreshing) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ResponsiveDetailPage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(
                      title: 'Muayene Kaydı',
                      icon: Icons.assignment_outlined,
                      leadingBack: true,
                      fallbackRoute: '/clinical-records',
                    ),
                    ClinicalEncounterIdentityBandFromEncounter(encounter: e),
                    ClinicalStackedSections(
                    children: [
                      ClinicalEncounterDetailSection(
                        title: 'Muayene Kimliği',
                        rows: ClinicalEncounterDetailSections.identity(e),
                      ),
                      ClinicalEncounterDetailSection(
                        title: 'Şikayet / Hikaye',
                        rows: ClinicalEncounterDetailSections.complaintStory(e),
                      ),
                      ClinicalEncounterDetailSection(
                        title: 'Muayene',
                        rows: ClinicalEncounterDetailSections.examination(e),
                      ),
                      ClinicalEncounterDetailSection(
                        title: 'Görüntüleme',
                        rows: ClinicalEncounterDetailSections.imaging(e),
                      ),
                      ClinicalEncounterDetailSection(
                        title: ClinicalEncounterDiagnosisDisplay.sectionTitle,
                        rows: ClinicalEncounterDetailSections.diagnosis(e),
                      ),
                      ClinicalEncounterDetailSection(
                        title: 'Tedavi Planı',
                        rows: ClinicalEncounterDetailSections.treatmentPlan(e),
                      ),
                      ClinicalEncounterDetailSection(
                        title: 'Fizyoterapi / Egzersiz / Kontrol',
                        rows:
                            ClinicalEncounterDetailSections.physiotherapyControl(
                          e,
                        ),
                      ),
                      if (ClinicalEncounterDetailDisplay
                          .showInternalDoctorNoteSection)
                        ClinicalEncounterDetailSection(
                          title: ClinicalEncounterDetailDisplay
                              .internalNoteSectionTitle(usesRemote: usesRemote),
                          rows: internalRows
                              .map(
                                (row) => InfoSectionRow(
                                  row.label,
                                  row.value,
                                  emphasize: row.emphasize,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                  DetailActionsPanel(
                    topSpacing: 0,
                    actions: [
                      if (AuthSession.canEditPrescriptions)
                        DetailAction(
                          label: 'Reçete Yaz',
                          icon: Icons.medication_outlined,
                          onPressed: () => context.push(
                            '/prescriptions/new?patientId=${e.patientId}&clinicalEncounterId=${e.id}',
                          ),
                        ),
                      if (AuthSession.canEditClinicalReports)
                        DetailAction(
                          label: 'Rapor Düzenle',
                          icon: Icons.description_outlined,
                          onPressed: () => context.push(
                            '/clinical-reports/new?patientId=${e.patientId}&clinicalEncounterId=${e.id}',
                          ),
                        ),
                      if (AuthSession.canEditRadiologyOrders)
                        DetailAction(
                          label: 'Radyoloji İstemi',
                          icon: Icons.radar_outlined,
                          onPressed: () => context.push(
                            '/radiology-orders/new?patientId=${e.patientId}&clinicalEncounterId=${e.id}',
                          ),
                        ),
                      if (AuthSession.canEditLabOrders)
                        DetailAction(
                          label: 'Laboratuvar İstemi',
                          icon: Icons.biotech_outlined,
                          onPressed: () => context.push(
                            '/lab-orders/new?patientId=${e.patientId}&clinicalEncounterId=${e.id}',
                          ),
                        ),
                      if (ContextualPdfActions.canShowCreateAction(
                        patientId: e.patientId,
                      ))
                        DetailAction(
                          label: ContextualPdfActions.createLabel,
                          icon: Icons.picture_as_pdf_outlined,
                          onPressed: () => context.push(
                            ContextualPdfActions.newFromClinicalEncounter(
                              patientId: e.patientId,
                              clinicalEncounterId: e.id,
                            ),
                          ),
                        ),
                      if (AuthSession.canEditConsents)
                        DetailAction(
                          label: 'Ameliyat Onamı',
                          icon: Icons.assignment_turned_in_outlined,
                          onPressed: () => context.push(
                            '/consents/new?patientId=${e.patientId}&encounterId=${e.id}&type=ameliyatOnami',
                          ),
                        ),
                      if (canEdit)
                        DetailAction(
                          label: DetailActionLabels.physiotherapyRefer,
                          onPressed: () => context.push(
                            '/physiotherapy/referrals/new?patientId=${e.patientId}&clinicalEncounterId=${e.id}',
                          ),
                        ),
                      DetailAction(
                        label: DetailActionLabels.controlAppointment,
                        filled: true,
                        onPressed: () => context.push(
                          '/appointments/new?patientId=${e.patientId}',
                        ),
                      ),
                      if (canEdit)
                        DetailAction(
                          label: DetailActionLabels.edit,
                          icon: Icons.edit_outlined,
                          onPressed: () async {
                            await context.push(
                              '/clinical-records/$encounterId/edit',
                            );
                            ClinicalEncounterListRefresh.markStale();
                            onEditComplete();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

}
