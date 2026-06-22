import '../../../shared/widgets/clinical_stacked_sections.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/detail_action_labels.dart';
import '../../shared/widgets/detail_header_card.dart';
import '../../shared/widgets/info_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/clinical_list_panel.dart';
import '../clinical_encounter/post_encounter_wizard/widgets/patient_surgical_quote_banner.dart';
import '../clinical_encounter/data/assistant_clinical_summary_list_load_result.dart';
import '../clinical_encounter/data/assistant_clinical_summary_list_refresh.dart';
import '../clinical_encounter/data/assistant_clinical_summary_list_user_messages.dart';
import '../clinical_encounter/data/assistant_clinical_summary_patient_detail_data_source.dart';
import '../clinical_encounter/data/assistant_clinical_summary_patient_detail_display.dart';
import '../clinical_encounter/data/clinical_summary_module_availability.dart';
import '../clinical_encounter/data/clinical_encounter_list_load_result.dart';
import '../clinical_encounter/data/clinical_encounter_list_refresh.dart';
import '../clinical_encounter/data/clinical_encounter_list_user_messages.dart';
import '../clinical_encounter/data/clinical_encounter_patient_detail_data_source.dart';
import '../clinical_encounter/models/assistant_clinical_summary.dart';
import '../clinical_encounter/models/clinical_encounter.dart';
import '../clinical_encounter/widgets/patient_scoped_clinical_encounter_row.dart';
import '../patient_tags/data/patient_tag_module_availability.dart';
import '../patient_tags/data/patient_tag_repository_provider.dart';
import '../patient_tags/data/patient_tag_repository_contract.dart';
import '../patient_tags/models/patient_tag.dart';
import '../patient_tags/widgets/patient_tag_chip.dart';
import '../patient_tags/widgets/patient_tag_selector_dialog.dart';
import '../physiotherapy/data/patient_rehab_last_session_display.dart';
import '../physiotherapy/data/patient_rehab_referral_summary_data_source.dart';
import '../physiotherapy/data/patient_rehab_referral_summary_display.dart';
import '../physiotherapy/data/patient_rehab_summary_load_result.dart';
import '../physiotherapy/data/physiotherapy_referral_list_refresh.dart';
import '../physiotherapy/data/physiotherapy_session_list_refresh.dart';
import '../physiotherapy/data/physiotherapy_referral_user_messages.dart';
import '../physiotherapy/models/physiotherapy_referral.dart';
import '../patient_files/data/patient_file_metadata_list_data_source.dart';
import '../patient_files/data/patient_file_metadata_list_load_result.dart';
import '../patient_files/data/patient_file_metadata_module_availability.dart';
import '../patient_files/presentation/patient_file_metadata_list_content.dart';
import '../timeline/data/timeline_module_availability.dart';
import 'widgets/patient_profile_completion_banner.dart';
import '../consents/widgets/consent_gate_modal.dart';
import 'data/patient_detail_data_source.dart';
import 'data/patient_detail_load_result.dart';
import 'data/patient_detail_user_messages.dart';
import 'data/patient_list_refresh.dart';
import 'data/patient_identity_privacy.dart';
import 'data/patient_remote_display.dart';
import 'models/patient.dart';
import 'patient_display_helpers.dart';
import 'patient_detail/patient_detail_action_context.dart';
import 'patient_detail/patient_detail_action_list.dart';
import 'patient_detail/patient_detail_action_registry.dart';
import 'widgets/patient_premium_surfaces.dart';

const int _kMaxHeaderTags = 3;

Widget? _patientDetailCardTrailing(
  PatientDetailActionContext ctx,
  PatientDetailCardKind kind,
) {
  final actions = PatientDetailActionRegistry.cardTrailingActions(ctx, kind);
  if (actions.isEmpty) return null;
  return PatientDetailCardTrailingBar(
    actionContext: ctx,
    actions: actions,
  );
}

/// Hasta detay kartı — başlık kart içinde, dış section başlığı yok.
class _PatientDetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _PatientDetailCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: PatientPremiumSurfaces.card(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _PatientCardTitle(title)),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _PatientCardTitle extends StatelessWidget {
  final String title;

  const _PatientCardTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
    );
  }
}

/// InfoSectionCard satırları — tek kart kabuğu içinde kullanılır.
class _PatientInfoRows extends StatelessWidget {
  final List<InfoSectionRow> rows;

  const _PatientInfoRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    final allEmpty = rows.every((r) => r.value == kDisplayUnspecified);

    if (allEmpty) {
      return Text(
        'Bu bölümde kayıtlı bilgi yok.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  child: Text(
                    row.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    style: (row.emphasize
                            ? Theme.of(context).textTheme.bodyMedium
                            : Theme.of(context).textTheme.bodySmall)
                        ?.copyWith(
                      fontWeight:
                          row.emphasize ? FontWeight.w600 : FontWeight.normal,
                      color: row.emphasize
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class PatientDetailScreen extends StatefulWidget {
  final String id;

  const PatientDetailScreen({super.key, required this.id});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Future<PatientDetailLoadResult> _loadFuture;
  bool _activatedOnce = false;

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
      _loadFuture = PatientDetailDataSource.loadById(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PatientDetailLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppShell(
            title: 'Hasta Detayı',
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _statusShell(
            context,
            title: 'Hasta bulunamadı',
            message: PatientDetailUserMessages.genericLoadFailure,
            showRetry: true,
          );
        }

        final result = snapshot.data;
        if (result == null) {
          return _statusShell(
            context,
            title: 'Hasta bulunamadı',
            message: PatientDetailUserMessages.genericLoadFailure,
            showRetry: true,
          );
        }

        if (result.hasError) {
          return _statusShell(
            context,
            title: 'Hasta detayı yüklenemedi',
            message: result.errorMessage,
            showRetry: true,
          );
        }

        if (result.patient == null) {
          return _statusShell(
            context,
            title: 'Hasta bulunamadı',
            message: 'Kayıt bulunamadı veya erişim yok.',
            showRetry: false,
          );
        }

        return ConsentGateScope(
          patientId: result.patient!.id,
          child: _PatientDetailLoadedView(patient: result.patient!),
        );
      },
    );
  }

  Widget _statusShell(
    BuildContext context, {
    required String title,
    required String? message,
    required bool showRetry,
  }) {
    return AppShell(
      title: 'Hasta Detayı',
      child: ClinicalStateMessage.error(
        icon: Icons.error_outline,
        title: title,
        description: ClinicalStateMessage.safeErrorDescription(message),
        onRetry: showRetry ? _reload : null,
      ),
    );
  }
}

class _PatientDetailLoadedView extends StatefulWidget {
  final Patient patient;

  const _PatientDetailLoadedView({required this.patient});

  static bool get _showsDoctorClinical => AuthSession.canViewClinicalEncounters;

  static bool get _showsAssistantClinical =>
      AuthSession.canViewClinicalDiagnosisSummary &&
      !AuthSession.canViewClinicalEncounters &&
      ClinicalSummaryModuleAvailability.assistantOperational;

  static bool get _showsRehabShort => AuthSession.canViewClinicalEncounters;

  @override
  State<_PatientDetailLoadedView> createState() =>
      _PatientDetailLoadedViewState();
}

class _PatientDetailLoadedViewState extends State<_PatientDetailLoadedView> {
  late Patient _patient;
  int _lastClinicalRefreshVersion = ClinicalEncounterListRefresh.version;
  bool _clinicalActivatedOnce = false;
  late Future<ClinicalEncounterListLoadResult> _clinicalFuture;
  ClinicalEncounterListLoadResult? _cachedClinical;

  int _lastAssistantRefreshVersion =
      AssistantClinicalSummaryListRefresh.version;
  bool _assistantActivatedOnce = false;
  late Future<AssistantClinicalSummaryListLoadResult> _assistantFuture;
  AssistantClinicalSummaryListLoadResult? _cachedAssistant;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _reloadClinical();
    _reloadAssistant();
  }

  Future<void> _onPatientTagsChanged() async {
    final refreshed =
        await RepositoryRegistry.patientsAsync.getById(_patient.id);
    if (refreshed != null && mounted) {
      setState(() => _patient = refreshed);
    }
  }

  @override
  void activate() {
    super.activate();
    if (_PatientDetailLoadedView._showsDoctorClinical) {
      if (!_clinicalActivatedOnce) {
        _clinicalActivatedOnce = true;
      } else if (ClinicalEncounterListRefresh.isStale(
          _lastClinicalRefreshVersion)) {
        _reloadClinical();
      }
    }
    if (_PatientDetailLoadedView._showsAssistantClinical) {
      if (!_assistantActivatedOnce) {
        _assistantActivatedOnce = true;
      } else if (AssistantClinicalSummaryListRefresh.isStale(
        _lastAssistantRefreshVersion,
      )) {
        _reloadAssistant();
      }
    }
  }

  void _reloadClinical() {
    if (!_PatientDetailLoadedView._showsDoctorClinical) return;
    setState(() {
      _lastClinicalRefreshVersion = ClinicalEncounterListRefresh.version;
      _clinicalFuture = ClinicalEncounterPatientDetailDataSource.load(
        _patient.id,
      );
    });
  }

  void _reloadAssistant() {
    if (!_PatientDetailLoadedView._showsAssistantClinical) return;
    setState(() {
      _lastAssistantRefreshVersion =
          AssistantClinicalSummaryListRefresh.version;
      _assistantFuture = AssistantClinicalSummaryPatientDetailDataSource.load(
        _patient.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final patient = _patient;
    final pid = patient.id;
    final q = '?patientId=$pid';

    if (_PatientDetailLoadedView._showsDoctorClinical) {
      return FutureBuilder<ClinicalEncounterListLoadResult>(
        future: _clinicalFuture,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final result = snapshot.data;
          if (result != null && !result.hasError) {
            _cachedClinical = result;
          }
          final active = result ?? _cachedClinical;
          final encounters = active == null
              ? const <ClinicalEncounter>[]
              : ClinicalEncounterPatientDetailDataSource.sortedNewestFirst(
                  active.encounters,
                );

          return _buildScaffold(
            context,
            patient: patient,
            pid: pid,
            q: q,
            clinicalResult: active,
            clinicalEncounters: encounters,
            clinicalLoading: waiting && _cachedClinical == null,
            onClinicalRetry: _reloadClinical,
          );
        },
      );
    }

    if (_PatientDetailLoadedView._showsAssistantClinical) {
      return FutureBuilder<AssistantClinicalSummaryListLoadResult>(
        future: _assistantFuture,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final result = snapshot.data;
          if (result != null && !result.hasError) {
            _cachedAssistant = result;
          }
          final active = result ?? _cachedAssistant;
          final summaries = active == null
              ? const <AssistantClinicalSummary>[]
              : AssistantClinicalSummaryPatientDetailDataSource
                  .sortedNewestFirst(
                  active.summaries,
                );

          return _buildScaffold(
            context,
            patient: patient,
            pid: pid,
            q: q,
            assistantResult: active,
            assistantSummaries: summaries,
            assistantLoading: waiting && _cachedAssistant == null,
            onAssistantRetry: _reloadAssistant,
          );
        },
      );
    }

    return _buildScaffold(
      context,
      patient: patient,
      pid: pid,
      q: q,
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required Patient patient,
    required String pid,
    required String q,
    ClinicalEncounterListLoadResult? clinicalResult,
    List<ClinicalEncounter>? clinicalEncounters,
    bool clinicalLoading = false,
    VoidCallback? onClinicalRetry,
    AssistantClinicalSummaryListLoadResult? assistantResult,
    List<AssistantClinicalSummary>? assistantSummaries,
    bool assistantLoading = false,
    VoidCallback? onAssistantRetry,
  }) {
    final actionCtx = PatientDetailActionContext.fromView(
      patientId: pid,
      clinicalEncounters: clinicalEncounters,
      showsAssistantClinical: _PatientDetailLoadedView._showsAssistantClinical,
    );
    final listActions = PatientDetailActionRegistry.listActions(actionCtx);

    final bodyCards = <Widget>[
      _PatientBasicInfoCard(
        patient: patient,
        onTagsChanged: _onPatientTagsChanged,
      ),
      if (AuthSession.canViewFiles &&
          PatientFileMetadataModuleAvailability.isOperational)
        _PatientFileMetadataSection(
          patientId: pid,
          actionContext: actionCtx,
        ),
      if (_PatientDetailLoadedView._showsDoctorClinical)
        _PatientDoctorClinicalSection(
          patientId: pid,
          result: clinicalResult,
          encounters: clinicalEncounters ?? const [],
          isLoading: clinicalLoading,
          onRetry: onClinicalRetry ?? _reloadClinical,
          onEncounterOpen: (encounterId) async {
            await context.push('/clinical-records/$encounterId');
            if (mounted &&
                ClinicalEncounterListRefresh.isStale(
                    _lastClinicalRefreshVersion)) {
              _reloadClinical();
            }
          },
        ),
      if (_PatientDetailLoadedView._showsAssistantClinical)
        _PatientAssistantClinicalSection(
          patientId: pid,
          result: assistantResult,
          summaries: assistantSummaries ?? const [],
          isLoading: assistantLoading,
          onRetry: onAssistantRetry ?? _reloadAssistant,
          actionContext: actionCtx,
        ),
      if (_PatientDetailLoadedView._showsRehabShort)
        _PatientRehabShortSummary(
          patientId: pid,
          actionContext: actionCtx,
        ),
    ];

    return AppShell(
      title: 'Hasta Detayı',
      child: ResponsiveDetailPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Hasta Detayı',
              icon: Icons.person_outline,
              leadingBack: true,
              fallbackRoute: '/patients',
              actions: _buildPatientDetailHeaderActions(
                context,
                patientId: pid,
                onAfterClinicalCreate: _reloadClinical,
              ),
            ),
            _PatientHeaderCard(
              patient: patient,
              onTagsChanged: _onPatientTagsChanged,
            ),
            PatientProfileCompletionBanner(
              patient: patient,
              onComplete: AuthSession.canEditPatients
                  ? () => context.push('/patients/${patient.id}/edit')
                  : null,
            ),
            PatientSurgicalQuoteBanner(patientId: pid),
            _PatientRoleShortSummary(
              patient: patient,
              patientId: pid,
              latestEncounter: clinicalEncounters == null
                  ? null
                  : ClinicalEncounterPatientDetailDataSource.latest(
                      clinicalEncounters,
                    ),
              clinicalLoading: clinicalLoading,
              assistantSummaryCount: assistantSummaries?.length,
              assistantSummaryLoading: assistantLoading,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClinicalStackedSections(children: bodyCards),
            if (listActions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              PatientDetailActionList(
                actionContext: actionCtx,
                actions: listActions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

List<Widget> _buildPatientDetailHeaderActions(
  BuildContext context, {
  required String patientId,
  VoidCallback? onAfterClinicalCreate,
}) {
  if (AuthSession.canEditClinicalEncounters) {
    return [
      _compactPatientHeaderButton(
        label: 'Yeni Muayene',
        icon: Icons.add_rounded,
        filled: true,
        onPressed: () async {
          await context.push('/clinical-records/new?patientId=$patientId');
          onAfterClinicalCreate?.call();
        },
      ),
    ];
  }

  if (AuthSession.canViewClinicalDiagnosisSummary &&
      !AuthSession.canViewClinicalEncounters &&
      AuthSession.canViewAppointments) {
    return [
      _compactPatientHeaderButton(
        label: 'Yeni Randevu',
        icon: Icons.event_outlined,
        onPressed: () =>
            context.push('/appointments/new?patientId=$patientId'),
      ),
    ];
  }

  if (AuthSession.canViewPhysiotherapy &&
      !AuthSession.canViewClinicalEncounters &&
      AuthSession.canBookReferralAppointments) {
    return [
      _compactPatientHeaderButton(
        label: 'FTR Randevusu',
        icon: Icons.healing_outlined,
        onPressed: () => context.push(
          '/appointments/new?patientId=$patientId&type=fizikTedavi',
        ),
      ),
    ];
  }

  return const [];
}

Widget _compactPatientHeaderButton({
  required String label,
  required IconData icon,
  required VoidCallback onPressed,
  bool filled = false,
}) {
  const density = VisualDensity.compact;
  const iconSize = 16.0;
  const padding = EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  if (filled) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      label: Text(label),
      style: FilledButton.styleFrom(
        visualDensity: density,
        padding: padding,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  return OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: iconSize),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      visualDensity: density,
      padding: padding,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );
}

class _PatientHeaderCard extends StatefulWidget {
  final Patient patient;
  final Future<void> Function()? onTagsChanged;

  const _PatientHeaderCard({
    required this.patient,
    this.onTagsChanged,
  });

  @override
  State<_PatientHeaderCard> createState() => _PatientHeaderCardState();
}

class _PatientHeaderCardState extends State<_PatientHeaderCard> {
  late Future<List<PatientTag>> _tagsFuture;

  @override
  void initState() {
    super.initState();
    _reloadTags();
  }

  @override
  void didUpdateWidget(_PatientHeaderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient.tagIds != widget.patient.tagIds) {
      _reloadTags();
    }
  }

  void _reloadTags() {
    _tagsFuture = _loadHeaderTags();
  }

  Future<List<PatientTag>> _loadHeaderTags() async {
    if (!PatientTagModuleAvailability.isOperational) {
      return const [];
    }
    try {
      return await PatientTagRepositoryProvider.repository
          .getByIds(widget.patient.tagIds);
    } on PatientTagRepositoryException catch (e) {
      if (e.failure == PatientTagRepositoryFailure.notConfigured) {
        return const [];
      }
      rethrow;
    }
  }

  Future<void> _removeTag(String tagId) async {
    await PatientTagRepositoryProvider.repository.removeFromPatient(
      patientId: widget.patient.id,
      tagId: tagId,
    );
    await widget.onTagsChanged?.call();
    if (mounted) {
      _reloadTags();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final canViewTags = AuthSession.canViewPatientTags &&
        PatientTagModuleAvailability.isOperational;
    final showTagChips =
        canViewTags && PatientRemoteDisplay.showTags(widget.patient);

    return FutureBuilder<List<PatientTag>>(
      future: _tagsFuture,
      builder: (context, snapshot) {
        final tags = snapshot.data ?? const <PatientTag>[];
        final visibleTags = tags.take(_kMaxHeaderTags).toList();
        final overflow = tags.length - visibleTags.length;

        return DetailHeaderCard(
          title: widget.patient.fullName,
          subtitle:
              'Dosya ${widget.patient.fileNumber} • ${widget.patient.age} yaş',
          chips: [
            if (showTagChips && visibleTags.isNotEmpty)
              ...visibleTags.map(
                (tag) => PatientTagChip(
                  tag: tag,
                  onRemove: AuthSession.canRemovePatientTags
                      ? () => _removeTag(tag.id)
                      : null,
                ),
              ),
            if (showTagChips && overflow > 0)
              Chip(
                label: Text('+$overflow'),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        );
      },
    );
  }
}

class _PatientRoleShortSummary extends StatelessWidget {
  final Patient patient;
  final String patientId;
  final ClinicalEncounter? latestEncounter;
  final bool clinicalLoading;
  final int? assistantSummaryCount;
  final bool assistantSummaryLoading;

  const _PatientRoleShortSummary({
    required this.patient,
    required this.patientId,
    this.latestEncounter,
    this.clinicalLoading = false,
    this.assistantSummaryCount,
    this.assistantSummaryLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return _PatientDetailCard(
      title: 'Özet',
      child: _PatientInfoRows(rows: _roleSummaryRows()),
    );
  }

  List<InfoSectionRow> _roleSummaryRows() {
    if (AuthSession.canViewClinicalEncounters) {
      return _doctorSummaryRows();
    }
    if (AuthSession.canViewClinicalDiagnosisSummary) {
      return _assistantSummaryRows();
    }
    return _nurseSummaryRows();
  }

  List<InfoSectionRow> _doctorSummaryRows() {
    if (clinicalLoading && latestEncounter == null) {
      return [
        InfoSectionRow(
          'Klinik durum',
          'Muayene kayıtları yükleniyor…',
          emphasize: true,
        ),
        InfoSectionRow(
          'Son başvuru',
          _formatDate(patient.lastVisitDate),
        ),
      ];
    }

    final latest = latestEncounter;
    if (latest == null) {
      return [
        InfoSectionRow(
          'Klinik durum',
          'Muayene kaydı bekleniyor',
          emphasize: true,
        ),
        InfoSectionRow(
          'Son başvuru',
          _formatDate(patient.lastVisitDate),
        ),
      ];
    }
    final control = latest.controlDate != null
        ? _formatDate(latest.controlDate!)
        : kDisplayUnspecified;
    return [
      InfoSectionRow(
        'Son muayene',
        _formatDate(latest.createdAt),
        emphasize: true,
      ),
      InfoSectionRow(
        'Ön tanı/Tanı',
        _diagnosisLine(latest),
        emphasize: true,
      ),
      InfoSectionRow('Kontrol tarihi', control),
      InfoSectionRow('Takip durumu', latest.status.label),
    ];
  }

  List<InfoSectionRow> _assistantSummaryRows() {
    if (assistantSummaryLoading && assistantSummaryCount == null) {
      return [
        InfoSectionRow(
          'Operasyonel durum',
          'Randevu, onam ve tahsilat takibi',
          emphasize: true,
        ),
        InfoSectionRow(
          'Son başvuru',
          _formatDate(patient.lastVisitDate),
        ),
        InfoSectionRow(
          'Muayene özeti',
          'Klinik özet yükleniyor…',
        ),
        InfoSectionRow('İletişim', patient.phone),
      ];
    }

    final count = assistantSummaryCount ?? 0;
    final recordLine =
        count > 0 ? '$count kayıtlı muayene özeti' : 'Muayene özeti kaydı yok';
    return [
      InfoSectionRow(
        'Operasyonel durum',
        'Randevu, onam ve tahsilat takibi',
        emphasize: true,
      ),
      InfoSectionRow('Son başvuru', _formatDate(patient.lastVisitDate)),
      InfoSectionRow('Muayene özeti', recordLine),
      InfoSectionRow('İletişim', patient.phone),
    ];
  }

  List<InfoSectionRow> _nurseSummaryRows() {
    return [
      InfoSectionRow(
        'Hasta bağlamı',
        'Temel hasta bilgisi',
        emphasize: true,
      ),
      InfoSectionRow('Son başvuru', _formatDate(patient.lastVisitDate)),
      InfoSectionRow('Dosya no', patient.fileNumber),
      InfoSectionRow('Telefon', patient.phone),
    ];
  }
}

class _PatientBasicInfoCard extends StatefulWidget {
  final Patient patient;
  final Future<void> Function()? onTagsChanged;

  const _PatientBasicInfoCard({
    required this.patient,
    this.onTagsChanged,
  });

  @override
  State<_PatientBasicInfoCard> createState() => _PatientBasicInfoCardState();
}

class _PatientBasicInfoCardState extends State<_PatientBasicInfoCard> {
  Future<void> _openTagSelector() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => PatientTagSelectorDialog(patientId: widget.patient.id),
    );
    await widget.onTagsChanged?.call();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final birthStr = _formatDate(patient.birthDate);
    final lastVisitStr = _formatDate(patient.lastVisitDate);
    final policy = patient.displayValue(patient.policyNumber);
    final insuranceLine = patient.insuranceCompany.trim().isEmpty
        ? patient.insuranceType
        : '${patient.insuranceType} • ${patient.insuranceCompany}';
    final canAssign = AuthSession.canAssignPatientTags &&
        PatientTagModuleAvailability.isOperational;

    final ageGender = PatientDisplayHelpers.formatAgeGenderLine(patient);

    final rows = <InfoSectionRow>[
      InfoSectionRow('Dosya no', patient.fileNumber, emphasize: true),
      InfoSectionRow('Doğum tarihi', birthStr),
      InfoSectionRow('Yaş / Cinsiyet', ageGender),
      if (PatientRemoteDisplay.showNationality(patient))
        InfoSectionRow('Uyruk', patient.displayValue(patient.nationality)),
      if (PatientIdentityPrivacy.formatIdentityLineForDisplay(patient)
          case final identityLine?)
        InfoSectionRow('Kimlik', identityLine),
      if (PatientRemoteDisplay.showPhone(patient))
        InfoSectionRow('Telefon', patient.phone),
      if (PatientRemoteDisplay.showSecondaryPhone(patient))
        InfoSectionRow('İkinci telefon', patient.secondaryPhone),
      if (PatientRemoteDisplay.showEmail(patient))
        InfoSectionRow('E-posta', patient.email),
      if (PatientRemoteDisplay.showAddress(patient))
        InfoSectionRow(
            'Adres', PatientRemoteDisplay.formatAddressLine(patient)),
      if (PatientRemoteDisplay.showBloodType(patient))
        InfoSectionRow('Kan grubu', patient.displayValue(patient.bloodType)),
      if (PatientRemoteDisplay.showOccupation(patient))
        InfoSectionRow('Meslek', patient.displayValue(patient.occupation)),
      if (PatientRemoteDisplay.showSportBranch(patient))
        InfoSectionRow(
            'Spor branşı', patient.displayValue(patient.sportBranch)),
      if (PatientRemoteDisplay.showInsurance(patient))
        InfoSectionRow('Sigorta', insuranceLine),
      if (PatientRemoteDisplay.showPolicy(patient))
        InfoSectionRow('Poliçe', policy),
      InfoSectionRow('Son başvuru', lastVisitStr),
    ];

    final emergencyRows = <InfoSectionRow>[];
    if (PatientRemoteDisplay.showEmergencyContact(patient)) {
      if (patient.emergencyContactName.trim().isNotEmpty) {
        emergencyRows.add(
          InfoSectionRow(
            'Ad soyad',
            patient.displayValue(patient.emergencyContactName),
          ),
        );
      }
      if (patient.emergencyContactRelation.trim().isNotEmpty) {
        emergencyRows.add(
          InfoSectionRow(
            'Yakınlık',
            patient.displayValue(patient.emergencyContactRelation),
          ),
        );
      }
      if (patient.emergencyContactPhone.trim().isNotEmpty) {
        emergencyRows.add(
          InfoSectionRow(
            'Telefon',
            patient.displayValue(patient.emergencyContactPhone),
          ),
        );
      }
      if (patient.emergencyContactNote.trim().isNotEmpty) {
        emergencyRows.add(
          InfoSectionRow(
            'Not',
            patient.displayValue(patient.emergencyContactNote),
          ),
        );
      }
    }

    return _PatientDetailCard(
      title: 'Temel Bilgiler',
      trailing: AuthSession.canEditPatients
          ? OutlinedButton.icon(
              onPressed: () async {
                await context.push('/patients/${patient.id}/edit');
                PatientListRefresh.markStale();
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text(DetailActionLabels.edit),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PatientInfoRows(rows: rows),
          if (emergencyRows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Acil kişi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _PatientInfoRows(rows: emergencyRows),
          ],
          if (canAssign) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openTagSelector,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Etiket Ekle'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PatientDoctorClinicalSection extends StatelessWidget {
  final String patientId;
  final ClinicalEncounterListLoadResult? result;
  final List<ClinicalEncounter> encounters;
  final bool isLoading;
  final VoidCallback onRetry;
  final Future<void> Function(String encounterId) onEncounterOpen;

  const _PatientDoctorClinicalSection({
    required this.patientId,
    required this.result,
    required this.encounters,
    required this.isLoading,
    required this.onRetry,
    required this.onEncounterOpen,
  });

  static const int _previewLimit = 5;

  @override
  Widget build(BuildContext context) {
    if (isLoading && result == null) {
      return _PatientDetailCard(
        title: 'Muayene Kayıtları',
        child: ClinicalStateMessage.loading(
          message: ClinicalEncounterListUserMessages.loading,
        ),
      );
    }

    if (result != null && result!.hasError) {
      return _PatientDetailCard(
        title: 'Muayene Kayıtları',
        child: ClinicalStateMessage.error(
          icon: Icons.error_outline,
          title: 'Muayene kayıtları yüklenemedi',
          description: ClinicalStateMessage.safeErrorDescription(
            result!.errorMessage,
          ),
          onRetry: onRetry,
        ),
      );
    }

    if (encounters.isEmpty) {
      return _PatientDetailCard(
        title: 'Muayene Kayıtları',
        child: ClinicalStateMessage.empty(
          icon: Icons.assignment_outlined,
          title: 'Bu hasta için henüz muayene kaydı bulunmuyor.',
          description: AuthSession.canEditClinicalEncounters
              ? 'Üstteki Yeni muayene ile kayıt oluşturabilirsiniz.'
              : null,
        ),
      );
    }

    final preview = encounters.take(_previewLimit).toList();
    final usesRemote = RepositoryRegistry.usesRemoteClinicalEncounters;

    return _PatientDetailCard(
      title: 'Muayene Kayıtları',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClinicalListPanel(
            children: [
              for (final encounter in preview)
                PatientScopedClinicalEncounterRow(
                  encounter: encounter,
                  usesRemote: usesRemote,
                  onTap: () => onEncounterOpen(encounter.id),
                ),
            ],
          ),
          if (encounters.length > _previewLimit) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    context.push('/clinical-records?patientId=$patientId'),
                child: Text('Tüm muayene kayıtları (${encounters.length})'),
              ),
            ),
          ],
          if (AuthSession.canViewPatientTimeline &&
              TimelineModuleAvailability.isOperational) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    context.push('/patient-timeline?patientId=$patientId'),
                icon: const Icon(Icons.timeline_outlined, size: 18),
                label: const Text('Klinik timeline'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PatientAssistantClinicalSection extends StatelessWidget {
  final String patientId;
  final AssistantClinicalSummaryListLoadResult? result;
  final List<AssistantClinicalSummary> summaries;
  final bool isLoading;
  final VoidCallback onRetry;
  final PatientDetailActionContext actionContext;

  const _PatientAssistantClinicalSection({
    required this.patientId,
    required this.result,
    required this.summaries,
    required this.isLoading,
    required this.onRetry,
    required this.actionContext,
  });

  @override
  Widget build(BuildContext context) {
    final trailing = _patientDetailCardTrailing(
      actionContext,
      PatientDetailCardKind.assistantSummary,
    );

    if (isLoading && result == null) {
      return _PatientDetailCard(
        title: 'Klinik Özet',
        trailing: trailing,
        child: ClinicalStateMessage.loading(
          message: AssistantClinicalSummaryListUserMessages.loading,
        ),
      );
    }

    if (result != null && result!.hasError) {
      return _PatientDetailCard(
        title: 'Klinik Özet',
        trailing: trailing,
        child: ClinicalStateMessage.error(
          icon: Icons.error_outline,
          title: AssistantClinicalSummaryListUserMessages.errorTitle,
          description: ClinicalStateMessage.safeErrorDescription(
            result!.errorMessage,
          ),
          onRetry: onRetry,
        ),
      );
    }

    final latest = AssistantClinicalSummaryPatientDetailDataSource.latest(
      summaries,
    );

    if (latest == null) {
      return _PatientDetailCard(
        title: 'Klinik Özet',
        trailing: trailing,
        child: ClinicalStateMessage.empty(
          icon: Icons.assignment_outlined,
          title: 'Bu hasta için tanı özeti kaydı bulunmuyor.',
        ),
      );
    }

    return _PatientDetailCard(
      title: 'Klinik Özet',
      trailing: trailing,
      child: _AssistantClinicalSummaryCard(summary: latest),
    );
  }
}

class _AssistantClinicalSummaryCard extends StatelessWidget {
  final AssistantClinicalSummary summary;

  const _AssistantClinicalSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return _PatientInfoRows(
      rows: AssistantClinicalSummaryPatientDetailDisplay.cardRows(summary),
    );
  }
}

class _PatientRehabShortSummary extends StatefulWidget {
  final String patientId;
  final PatientDetailActionContext actionContext;

  const _PatientRehabShortSummary({
    required this.patientId,
    required this.actionContext,
  });

  @override
  State<_PatientRehabShortSummary> createState() =>
      _PatientRehabShortSummaryState();
}

class _PatientRehabShortSummaryState extends State<_PatientRehabShortSummary> {
  late Future<PatientRehabSummaryLoadResult> _loadFuture;
  int _lastReferralRefreshVersion = PhysiotherapyReferralListRefresh.version;
  int _lastSessionRefreshVersion = PhysiotherapySessionListRefresh.version;
  bool _activatedOnce = false;

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
    final referralStale = PhysiotherapyReferralListRefresh.isStale(
      _lastReferralRefreshVersion,
    );
    final sessionStale = PhysiotherapySessionListRefresh.isStale(
      _lastSessionRefreshVersion,
    );
    if (referralStale || sessionStale) {
      _reload();
    }
  }

  void _reload() {
    _lastReferralRefreshVersion = PhysiotherapyReferralListRefresh.version;
    _lastSessionRefreshVersion = PhysiotherapySessionListRefresh.version;
    setState(() {
      _loadFuture =
          PatientRehabReferralSummaryDataSource.loadSummary(widget.patientId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = '?patientId=${widget.patientId}';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final trailing = _patientDetailCardTrailing(
      widget.actionContext,
      PatientDetailCardKind.rehab,
    );

    return FutureBuilder<PatientRehabSummaryLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _PatientDetailCard(
            title: 'Rehabilitasyon Özeti',
            trailing: trailing,
            child: ClinicalStateMessage.loading(
              message: PhysiotherapyReferralListUserMessages.loading,
            ),
          );
        }

        final result = snapshot.data!;
        if (result.hasError) {
          return _PatientDetailCard(
            title: 'Rehabilitasyon Özeti',
            trailing: trailing,
            child: ClinicalStateMessage.error(
              icon: Icons.error_outline,
              title: PhysiotherapyReferralListUserMessages.errorTitle,
              description: result.errorMessage!,
              onRetry: _reload,
            ),
          );
        }

        final latest = PatientRehabReferralSummaryDisplay.latest(
          result.referrals ?? const [],
        );
        final latestSession = result.latestSession;

        final rows = <InfoSectionRow>[];
        if (latest == null) {
          rows.add(
            const InfoSectionRow(
              'Yönlendirme',
              'Aktif yönlendirme yok',
              emphasize: true,
            ),
          );
        } else {
          rows.addAll(_rehabSummaryRows(latest));
        }

        final sessionRows = latestSession != null
            ? PatientRehabLastSessionDisplay.summaryRows(latestSession)
            : const <InfoSectionRow>[];

        return _PatientDetailCard(
          title: 'Rehabilitasyon Özeti',
          trailing: trailing,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PatientInfoRows(rows: rows),
              if (sessionRows.isNotEmpty) ...[
                const Divider(
                  height: AppSpacing.lg,
                  color: AppColors.borderSoft,
                ),
                Text(
                  'Son FTR seansı',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _PatientInfoRows(rows: sessionRows),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push('/physiotherapy/referrals$q'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(
                    'Rehabilitasyon modülüne git',
                    style: TextStyle(color: muted),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

List<InfoSectionRow> _rehabSummaryRows(PhysiotherapyReferral latest) {
  final rows = <InfoSectionRow>[
    InfoSectionRow(
      'Yönlendirme',
      '${latest.statusLabel} • ${_formatDate(latest.referredAt)}',
      emphasize: true,
    ),
    InfoSectionRow('Tanı / neden', _shortLine(latest.diagnosisSummary)),
    InfoSectionRow('Tedavi hedefi', _shortLine(latest.treatmentGoal)),
  ];

  if (latest.doctorSummary.trim().isNotEmpty) {
    rows.add(InfoSectionRow('Doktor özeti', _shortLine(latest.doctorSummary)));
  }
  if (latest.plannedStartDate != null) {
    rows.add(
      InfoSectionRow(
        'Planlanan başlangıç',
        _formatDate(latest.plannedStartDate!),
      ),
    );
  }
  if (latest.notes.trim().isNotEmpty) {
    rows.add(InfoSectionRow('Takip notu', _shortLine(latest.notes)));
  }
  if (latest.targetReturnToSportDate != null) {
    rows.add(
      InfoSectionRow(
        'Spora dönüş hedefi',
        _formatDate(latest.targetReturnToSportDate!),
      ),
    );
  }

  return rows;
}

String _shortLine(String value) {
  final t = value.trim();
  if (t.isEmpty) return kDisplayUnspecified;
  if (t.length <= 80) return t;
  return '${t.substring(0, 77)}…';
}

String _diagnosisLine(ClinicalEncounter e) {
  final finalDx = e.finalDiagnosis.trim();
  if (finalDx.isNotEmpty) return finalDx;
  final prelim = e.preliminaryDiagnosis.trim();
  if (prelim.isNotEmpty) return prelim;
  return kDisplayUnspecified;
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}

class _PatientFileMetadataSection extends StatefulWidget {
  final String patientId;
  final PatientDetailActionContext actionContext;

  const _PatientFileMetadataSection({
    required this.patientId,
    required this.actionContext,
  });

  @override
  State<_PatientFileMetadataSection> createState() =>
      _PatientFileMetadataSectionState();
}

class _PatientFileMetadataSectionState
    extends State<_PatientFileMetadataSection> {
  static const int _previewLimit = 3;

  late Future<PatientFileMetadataListLoadResult> _loadFuture;
  PatientFileMetadataListLoadResult? _cachedResult;
  bool _activatedOnce = false;

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
      _cachedResult = null;
      _loadFuture = PatientFileMetadataListDataSource.load(
        patientId: widget.patientId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PatientDetailCard(
      title: 'Dosya ve PDF Kayıtları',
      trailing: _patientDetailCardTrailing(
        widget.actionContext,
        PatientDetailCardKind.file,
      ),
      child: FutureBuilder<PatientFileMetadataListLoadResult>(
        future: _loadFuture,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final result = snapshot.data;

          if (result != null && !result.hasError && !result.isNotConfigured) {
            _cachedResult = result;
          }

          return PatientFileMetadataListContent(
            isLoading: waiting && _cachedResult == null,
            result: result ?? _cachedResult,
            onRetry: _reload,
            maxItems: _previewLimit,
          );
        },
      ),
    );
  }
}
