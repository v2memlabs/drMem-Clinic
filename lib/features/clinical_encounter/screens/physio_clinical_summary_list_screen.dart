import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/clinical_separated_list_body.dart';
import '../../../shared/widgets/data_list_card.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/list_filters_row.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/clinical_role_summary_ui_states.dart';
import '../data/physiotherapist_clinical_summary_display.dart';
import '../data/physiotherapist_clinical_summary_list_data_source.dart';
import '../data/physiotherapist_clinical_summary_list_load_result.dart';
import '../data/physiotherapist_clinical_summary_list_state_messages.dart';
import '../data/physiotherapist_clinical_summary_list_user_messages.dart';
import '../models/clinical_encounter.dart';
import '../models/physiotherapist_clinical_summary.dart';

/// Fizyoterapist salt-okunur klinik özet — güvenli [PhysiotherapistClinicalSummary].
class PhysioClinicalSummaryListScreen extends StatefulWidget {
  final String? patientId;

  const PhysioClinicalSummaryListScreen({super.key, this.patientId});

  @override
  State<PhysioClinicalSummaryListScreen> createState() =>
      _PhysioClinicalSummaryListScreenState();
}

class _PhysioClinicalSummaryListScreenState
    extends State<PhysioClinicalSummaryListScreen> {
  String _search = '';
  ClinicalBodyRegion? _regionFilter;
  ClinicalEncounterStatus? _statusFilter;
  late Future<PhysiotherapistClinicalSummaryListLoadResult> _loadFuture;
  PhysiotherapistClinicalSummaryListLoadResult? _cachedResult;
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

  int get _activeFilterCount {
    var n = 0;
    if (_regionFilter != null) n++;
    if (_statusFilter != null) n++;
    return n;
  }

  void _clearFilters() {
    setState(() {
      _regionFilter = null;
      _statusFilter = null;
    });
    _reload();
  }

  void _reload() {
    setState(() {
      _cachedResult = null;
      _loadFuture = PhysiotherapistClinicalSummaryListDataSource.load(
        patientId: widget.patientId,
        search: _search,
        regionFilter: _regionFilter,
        statusFilter: _statusFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return AppShell(
      title: 'Klinik Özetler',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Klinik Özetler',
              icon: Icons.medical_information_outlined,
            ),
            FilterBar(
              searchHint: 'Hasta, tanı özeti, bölge veya FTR notu ara',
              onSearchChanged: (v) {
                _search = v;
                _reload();
              },
              filters: [
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<ClinicalBodyRegion?>(
                    value: _regionFilter,
                    decoration: const InputDecoration(
                      labelText: 'Bölge',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm bölgeler'),
                      ),
                      ...ClinicalBodyRegion.values.map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.label),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _regionFilter = v;
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<ClinicalEncounterStatus?>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm durumlar'),
                      ),
                      ...ClinicalEncounterStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      _statusFilter = v;
                      _reload();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Salt-okunur güvenli özet — tam muayene kaydı ve iç hekim notları '
              'gösterilmez.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<PhysiotherapistClinicalSummaryListLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return ClinicalRoleSummaryUiStates.listLoading(
            message: PhysiotherapistClinicalSummaryListUserMessages.loading,
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
            message: PhysiotherapistClinicalSummaryListUserMessages.loading,
          );
        }

        if (active.hasError) {
          return ClinicalRoleSummaryUiStates.listBodyWithRefresh(
            showRefreshBar: waiting,
            child: ClinicalRoleSummaryUiStates.listError(
              title: PhysiotherapistClinicalSummaryListUserMessages.errorTitle,
              description: active.errorMessage!,
              onRetry: _reload,
            ),
          );
        }

        if (active.isNotConfigured) {
          return ClinicalRoleSummaryUiStates.listBodyWithRefresh(
            showRefreshBar: waiting,
            child: ClinicalRoleSummaryUiStates.listNotConfigured(
              icon: Icons.medical_information_outlined,
              title: PhysiotherapistClinicalSummaryListUserMessages.notConfigured,
              description: PhysiotherapistClinicalSummaryListUserMessages
                  .notConfiguredDescription,
            ),
          );
        }

        final items = active.summaries;
        if (items.isEmpty) {
          final emptySourceList = active.sourceCountBeforeFilter == 0;
          return ClinicalRoleSummaryUiStates.listBodyWithRefresh(
            showRefreshBar: waiting,
            child: ClinicalRoleSummaryUiStates.listEmpty(
              icon: Icons.medical_information_outlined,
              title: PhysiotherapistClinicalSummaryListStateMessages.emptyTitle(
                search: _search,
                hasPatientFilter: _hasPatientFilter,
                hasRegionFilter: _regionFilter != null,
                hasStatusFilter: _statusFilter != null,
                emptySourceList: emptySourceList,
              ),
              description:
                  PhysiotherapistClinicalSummaryListStateMessages.emptyDescription(
                search: _search,
                hasPatientFilter: _hasPatientFilter,
                hasRegionFilter: _regionFilter != null,
                hasStatusFilter: _statusFilter != null,
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

  Widget _buildCard(
    BuildContext context,
    PhysiotherapistClinicalSummary summary,
  ) {
    return DataListCard(
      title: summary.patientDisplayName,
      subtitle: PhysiotherapistClinicalSummaryDisplay.listSubtitle(summary),
      metaLine: PhysiotherapistClinicalSummaryDisplay.listMetaLine(summary),
      trailing: PhysiotherapistClinicalSummaryDisplay.formatDate(
        summary.encounterDate,
      ),
      chips: PhysiotherapistClinicalSummaryDisplay.listChips(summary),
      onTap: () => context.push(
        '/physiotherapy/clinical-summaries/${summary.encounterId}',
      ),
    );
  }
}
