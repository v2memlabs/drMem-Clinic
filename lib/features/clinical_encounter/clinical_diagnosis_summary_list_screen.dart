import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/data_list_card.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/clinical_encounter_diagnosis_display.dart';
import 'data/assistant_clinical_summary_display.dart';
import 'data/assistant_clinical_summary_list_data_source.dart';
import 'data/assistant_clinical_summary_list_load_result.dart';
import 'data/assistant_clinical_summary_list_state_messages.dart';
import 'data/assistant_clinical_summary_list_user_messages.dart';
import 'data/clinical_role_summary_ui_states.dart';
import 'models/assistant_clinical_summary.dart';

/// Operasyonel tanı özeti — güvenli [AssistantClinicalSummary] projection.
class ClinicalDiagnosisSummaryListScreen extends StatefulWidget {
  final String? patientId;

  const ClinicalDiagnosisSummaryListScreen({super.key, this.patientId});

  @override
  State<ClinicalDiagnosisSummaryListScreen> createState() =>
      _ClinicalDiagnosisSummaryListScreenState();
}

class _ClinicalDiagnosisSummaryListScreenState
    extends State<ClinicalDiagnosisSummaryListScreen> {
  String _search = '';
  late Future<AssistantClinicalSummaryListLoadResult> _loadFuture;
  AssistantClinicalSummaryListLoadResult? _cachedResult;
  bool _activatedOnce = false;

  bool get _hasPatientFilter =>
      widget.patientId != null && widget.patientId!.isNotEmpty;

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
      _loadFuture = AssistantClinicalSummaryListDataSource.load(
        patientId: widget.patientId,
        search: _search,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: ClinicalEncounterDiagnosisDisplay.summaryTitle,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: ClinicalEncounterDiagnosisDisplay.summaryTitle,
              icon: Icons.healing_outlined,
            ),
            FilterBar(
              searchHint: 'Hasta veya tanı özeti ara',
              onSearchChanged: (v) {
                _search = v;
                _reload();
              },
              collapsible: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<AssistantClinicalSummaryListLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return ClinicalRoleSummaryUiStates.listLoading(
            message: AssistantClinicalSummaryListUserMessages.loading,
          );
        }

        if (result != null &&
            !result.hasError &&
            !result.isNotConfigured) {
          _cachedResult = result;
        }

        final active = result ?? _cachedResult;
        if (active == null) {
          return ClinicalRoleSummaryUiStates.listLoading(
            message: AssistantClinicalSummaryListUserMessages.loading,
          );
        }

        if (active.hasError) {
          return ClinicalRoleSummaryUiStates.listBodyWithRefresh(
            showRefreshBar: waiting,
            child: ClinicalRoleSummaryUiStates.listError(
              title: AssistantClinicalSummaryListUserMessages.errorTitle,
              description: active.errorMessage!,
              onRetry: _reload,
            ),
          );
        }

        if (active.isNotConfigured) {
          return ClinicalRoleSummaryUiStates.listBodyWithRefresh(
            showRefreshBar: waiting,
            child: ClinicalRoleSummaryUiStates.listNotConfigured(
              icon: Icons.healing_outlined,
              title: AssistantClinicalSummaryListUserMessages.notConfigured,
              description:
                  AssistantClinicalSummaryListUserMessages.notConfiguredDescription,
            ),
          );
        }

        final items = active.summaries;
        if (items.isEmpty) {
          final emptySourceList = active.sourceCountBeforeFilter == 0;
          return ClinicalRoleSummaryUiStates.listBodyWithRefresh(
            showRefreshBar: waiting,
            child: ClinicalRoleSummaryUiStates.listEmpty(
              icon: Icons.healing_outlined,
              title: AssistantClinicalSummaryListStateMessages.emptyTitle(
                search: _search,
                hasPatientFilter: _hasPatientFilter,
                emptySourceList: emptySourceList,
              ),
              description:
                  AssistantClinicalSummaryListStateMessages.emptyDescription(
                search: _search,
                hasPatientFilter: _hasPatientFilter,
                emptySourceList: emptySourceList,
              ),
            ),
          );
        }

        return ClinicalRoleSummaryUiStates.listBodyWithRefresh(
          showRefreshBar: waiting,
          child: ClinicalSeparatedListBody(
            children: [
              for (final summary in items) _buildCard(context, summary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, AssistantClinicalSummary summary) {
    final nextControl = AssistantClinicalSummaryDisplay.formatOptionalDate(
      summary.nextControlDate,
    );

    return DataListCard(
      title: summary.patientDisplayName,
      subtitle: AssistantClinicalSummaryDisplay.listSubtitle(summary),
      metaLine: AssistantClinicalSummaryDisplay.listMetaLine(summary),
      contextLine: nextControl != null ? 'Kontrol: $nextControl' : null,
      trailing: AssistantClinicalSummaryDisplay.formatDate(summary.encounterDate),
      chips: AssistantClinicalSummaryDisplay.listChips(summary),
      onTap: () => context.push(
        '/clinical-records/diagnosis-summary/${summary.encounterId}',
      ),
    );
  }
}
