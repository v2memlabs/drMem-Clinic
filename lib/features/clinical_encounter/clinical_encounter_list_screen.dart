import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_status_legend.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/clinical_encounter_list_data_source.dart';
import 'data/clinical_encounter_list_filters.dart';
import 'data/clinical_encounter_repository_provider.dart';
import 'data/clinical_encounter_list_load_result.dart';
import 'data/clinical_encounter_list_state_messages.dart';
import 'data/clinical_encounter_list_user_messages.dart';
import 'models/clinical_encounter.dart';
import 'widgets/clinical_encounter_clinical_list_row.dart';
import 'widgets/clinical_encounter_list_filters_row.dart';
import 'widgets/clinical_encounter_list_legend.dart';

class ClinicalEncounterListScreen extends StatefulWidget {
  final String? patientId;

  const ClinicalEncounterListScreen({super.key, this.patientId});

  @override
  State<ClinicalEncounterListScreen> createState() =>
      _ClinicalEncounterListScreenState();
}

class _ClinicalEncounterListScreenState extends State<ClinicalEncounterListScreen> {
  String _search = '';
  ClinicalVisitType? _visitFilter;
  ClinicalEncounterStatus? _statusFilter;
  ClinicalBodyRegion? _regionFilter;
  late Future<ClinicalEncounterListLoadResult> _loadFuture;
  Timer? _searchDebounce;
  ClinicalEncounterListLoadResult? _cachedResult;
  bool _activatedOnce = false;

  static const Duration _remoteSearchDebounce = Duration(milliseconds: 350);

  bool get _usesRemote => RepositoryRegistry.usesRemoteClinicalEncounters;

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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _loadFuture = ClinicalEncounterListDataSource.load(
        patientId: widget.patientId,
        search: _search,
        usesRemote: _usesRemote,
      );
    });
  }

  void _onSearchChanged(String value) {
    _search = value;
    _searchDebounce?.cancel();

    if (_usesRemote) {
      _searchDebounce = Timer(_remoteSearchDebounce, () {
        if (mounted) _reload();
      });
      return;
    }

    _reload();
  }

  void _onFilterChanged(VoidCallback apply) {
    setState(apply);
  }

  Future<void> _openDetail(String id) async {
    await context.push('/clinical-records/$id');
    if (mounted) _reload();
  }

  Future<void> _openNewEncounter() async {
    final route = _hasPatientFilter
        ? '/clinical-records/new?patientId=${widget.patientId}'
        : '/clinical-records/new';
    await context.push(route);
    if (mounted) _reload();
  }

  String get _searchHint => _usesRemote
      ? 'Protokol, hasta, tanı, ICD veya tedavi planı ara'
      : 'Protokol, hasta, şikayet, bölge, ön tanı veya plan ara';

  String get _newEncounterLabel => _hasPatientFilter
      ? 'Bu Hasta İçin Muayene'
      : 'Yeni Muayene';

  bool get _canCreateEncounter => AuthSession.canEditClinicalEncounters;

  int get _activeFilterCount {
    var n = 0;
    if (_visitFilter != null) n++;
    if (_statusFilter != null) n++;
    if (!_usesRemote && _regionFilter != null) n++;
    return n;
  }

  void _clearFilters() {
    setState(() {
      _visitFilter = null;
      _statusFilter = null;
      _regionFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Muayene Kayıtları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Muayene Kayıtları',
              icon: Icons.assignment_outlined,
            ),
            FilterBar(
              searchHint: _searchHint,
              onSearchChanged: _onSearchChanged,
              collapsible: true,
              activeFilterCount: _activeFilterCount,
              onClearFilters:
                  _activeFilterCount > 0 ? _clearFilters : null,
              trailing: _canCreateEncounter
                  ? FilledButton.icon(
                      onPressed: _openNewEncounter,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(_newEncounterLabel),
                    )
                  : null,
              filters: [
                ClinicalEncounterListFiltersRow(
                  visitFilter: _visitFilter,
                  statusFilter: _statusFilter,
                  regionFilter: _regionFilter,
                  onVisitChanged: (v) =>
                      _onFilterChanged(() => _visitFilter = v),
                  onStatusChanged: (v) =>
                      _onFilterChanged(() => _statusFilter = v),
                  onRegionChanged: (v) =>
                      _onFilterChanged(() => _regionFilter = v),
                  showRegionFilter: !_usesRemote,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildListBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody() {
    return FutureBuilder<ClinicalEncounterListLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (result != null && !result.hasError) {
          _cachedResult = result;
        }

        if (waiting && _cachedResult == null) {
          return ClinicalStateMessage.loading(
            message: ClinicalEncounterListUserMessages.loading,
          );
        }

        if (snapshot.hasError && _cachedResult == null) {
          return _errorState(
            ClinicalEncounterListUserMessages.genericLoadFailure,
          );
        }

        if (result == null && _cachedResult == null) {
          return _errorState(
            ClinicalEncounterListUserMessages.genericLoadFailure,
          );
        }

        final active = result ?? _cachedResult!;
        if (active.hasError && _cachedResult == null) {
          return _errorState(active.errorMessage);
        }

        if (active.hasError && result != null) {
          return Column(
            children: [
              if (waiting) const LinearProgressIndicator(minHeight: 2),
              Expanded(child: _errorState(active.errorMessage)),
            ],
          );
        }

        var list = active.encounters;
        list = ClinicalEncounterListFilters.applyVisitType(list, _visitFilter);
        list = ClinicalEncounterListFilters.applyStatus(list, _statusFilter);
        if (!_usesRemote) {
          list = ClinicalEncounterListFilters.applyBodyRegion(
            list,
            _regionFilter,
          );
        }

        if (list.isEmpty) {
          final emptyTitle = ClinicalEncounterListStateMessages.emptyTitle(
            search: _search,
            hasVisitFilter: _visitFilter != null,
            hasStatusFilter: _statusFilter != null,
            hasRegionFilter: _regionFilter != null,
            hasPatientFilter: _hasPatientFilter,
            emptySourceList: active.encounters.isEmpty,
          );
          final emptyDescription =
              ClinicalEncounterListStateMessages.emptyDescription(
            search: _search,
            hasVisitFilter: _visitFilter != null,
            hasStatusFilter: _statusFilter != null,
            hasRegionFilter: _regionFilter != null,
            hasPatientFilter: _hasPatientFilter,
            emptySourceList: active.encounters.isEmpty,
          );
          final polishedEmptyDescription =
              _usesRemote && active.encounters.isEmpty
                  ? (_hasPatientFilter
                        ? ClinicalEncounterListUserMessages.emptyForPatient
                        : ClinicalEncounterListUserMessages.emptyGeneric)
                  : emptyDescription;

          return Column(
            children: [
              if (waiting) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ClinicalStateMessage.empty(
                  icon: Icons.assignment_outlined,
                  title: emptyTitle,
                  description: polishedEmptyDescription,
                  action: _canCreateEncounter
                      ? OutlinedButton.icon(
                          onPressed: _openNewEncounter,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(_newEncounterLabel),
                        )
                      : null,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            if (waiting) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ClinicalSeparatedListBody(
                legend: ClinicalStatusLegend(
                  title: 'Durum renkleri',
                  items: ClinicalEncounterListLegend.items,
                ),
                children: [
                  for (final e in list)
                    ClinicalEncounterClinicalListRow(
                      encounter: e,
                      usesRemote: _usesRemote,
                      onTap: () => _openDetail(e.id),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _retryLoad() {
    ClinicalEncounterRepositoryProvider.resetCache();
    _reload();
  }

  Widget _errorState(String? message) {
    return ClinicalStateMessage.error(
      icon: Icons.error_outline,
      title: 'Liste yüklenemedi',
      description: ClinicalStateMessage.safeErrorDescription(message),
      onRetry: _retryLoad,
    );
  }

}
