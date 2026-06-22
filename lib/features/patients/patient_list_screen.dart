import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/app_breakpoints.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/page_header.dart';
import 'data/patient_list_data_source.dart';
import 'data/patient_list_load_result.dart';
import 'data/patient_list_refresh.dart';
import 'data/patient_list_state_messages.dart';
import 'data/patient_list_user_messages.dart';
import 'models/patient.dart';
import 'patient_display_helpers.dart';
import 'widgets/patient_alphabet_index_bar.dart';
import 'widgets/patient_compact_card.dart';
import 'widgets/patient_compact_list_row.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  String _query = '';
  String? _letterFilter;
  late Future<PatientListLoadResult> _loadFuture;
  Timer? _searchDebounce;
  PatientListLoadResult? _cachedResult;
  bool _loadingMore = false;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PatientListRefresh.version;

  static const Duration _remoteSearchDebounce = Duration(milliseconds: 350);

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
    if (PatientListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _reload() {
    _lastRefreshVersion = PatientListRefresh.version;
    setState(() {
      _loadFuture = PatientListDataSource.load(_query);
    });
  }

  Future<void> _loadMore() async {
    final current = _cachedResult;
    final cursor = current?.nextCursor;
    if (_loadingMore || current == null || cursor == null) return;

    setState(() => _loadingMore = true);
    final next = await PatientListDataSource.load(_query, after: cursor);
    if (!mounted) return;

    if (next.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ClinicalStateMessage.safeErrorDescription(next.errorMessage),
          ),
        ),
      );
      setState(() => _loadingMore = false);
      return;
    }

    setState(() {
      _cachedResult = PatientListLoadResult.success(
        [...current.patients, ...next.patients],
        nextCursor: next.nextCursor,
      );
      _loadingMore = false;
    });
  }

  void _onSearchChanged(String value) {
    _query = value;
    _searchDebounce?.cancel();

    if (RepositoryRegistry.usesRemotePatients) {
      _searchDebounce = Timer(_remoteSearchDebounce, () {
        if (mounted) _reload();
      });
      return;
    }

    _reload();
  }

  Future<void> _openPatient(String id) async {
    await context.push('/patients/$id');
    if (mounted && PatientListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  Future<void> _openNewPatient() async {
    await context.push('/patients/new');
    if (mounted && PatientListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  String get _searchHint => RepositoryRegistry.usesRemotePatients
      ? 'Ad, dosya no, kimlik veya telefon'
      : 'Ad, dosya no, kimlik, telefon veya şikayet';

  List<Widget> _buildAlphabetFilters() {
    final cached = _cachedResult;
    if (cached == null || cached.hasError) return const [];

    final sorted = PatientDisplayHelpers.sortByLastName(cached.patients);
    final enabledLetters = PatientDisplayHelpers.enabledIndexLetters(sorted);
    return [
      PatientAlphabetIndexBar(
        selectedLetter: _letterFilter,
        enabledLetters: enabledLetters,
        onLetterSelected: (letter) {
          setState(() => _letterFilter = letter);
        },
      ),
    ];
  }

  List<Patient> _prepareDisplayList(List<Patient> source) {
    final sorted = PatientDisplayHelpers.sortByLastName(source);
    if (_letterFilter == null) return sorted;
    return sorted
        .where(
            (p) => PatientDisplayHelpers.matchesLetterFilter(p, _letterFilter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Hasta Listesi',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Hastalar',
              icon: Icons.people_outline,
            ),
            FilterBar(
              searchHint: _searchHint,
              onSearchChanged: _onSearchChanged,
              collapsible: _cachedResult != null,
              activeFilterCount: _letterFilter != null ? 1 : 0,
              onClearFilters: _letterFilter != null
                  ? () => setState(() => _letterFilter = null)
                  : null,
              trailing: AuthSession.canEditPatients
                  ? FilledButton.icon(
                      onPressed: _openNewPatient,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Hasta'),
                    )
                  : null,
              filters: _buildAlphabetFilters(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildListBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody() {
    return FutureBuilder<PatientListLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (result != null &&
            !result.hasError &&
            !identical(_cachedResult, result)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _cachedResult = result);
          });
        }

        if (waiting && _cachedResult == null) {
          return ClinicalStateMessage.loading(
            message: PatientListUserMessages.loading,
          );
        }

        if (snapshot.hasError && _cachedResult == null) {
          return _errorState(PatientListUserMessages.genericLoadFailure);
        }

        if (result == null && _cachedResult == null) {
          return _errorState(PatientListUserMessages.genericLoadFailure);
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

        final displayList = _prepareDisplayList(active.patients);

        if (displayList.isEmpty) {
          return Column(
            children: [
              if (waiting) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ClinicalStateMessage.empty(
                  icon: Icons.people_outline,
                  title: _letterFilter != null
                      ? 'Bu harf için hasta bulunamadı'
                      : PatientListStateMessages.emptyTitle(query: _query),
                  description: PatientListStateMessages.emptyDescription(
                    query: _query,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            if (waiting) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final useTable =
                      constraints.maxWidth >= AppBreakpoints.tabletLandscape;
                  if (useTable) {
                    return _buildTableList(displayList);
                  }
                  return _buildCardList(displayList);
                },
              ),
            ),
            if (active.hasMore) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label:
                    Text(_loadingMore ? 'Yükleniyor...' : 'Daha fazla yükle'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTableList(List<Patient> patients) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const PatientCompactListHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return PatientCompactListRow(
                  patient: patient,
                  onTap: () => _openPatient(patient.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(List<Patient> patients) {
    return ListView.separated(
      itemCount: patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final patient = patients[index];
        return PatientCompactCard(
          patient: patient,
          onTap: () => _openPatient(patient.id),
        );
      },
    );
  }

  Widget _errorState(String? message) {
    return ClinicalStateMessage.error(
      icon: Icons.error_outline,
      title: 'Hasta listesi yüklenemedi',
      description: ClinicalStateMessage.safeErrorDescription(message),
      onRetry: _reload,
    );
  }
}
