import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/data_list_card.dart';
import '../../../shared/widgets/clinical_separated_list_body.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/exercise_plan_list_data_source.dart';
import '../data/exercise_plan_list_refresh.dart';
import '../models/exercise_plan.dart';

class ExercisePlanListScreen extends StatefulWidget {
  final String? patientId;
  final bool? initialApprovedByDoctor;

  const ExercisePlanListScreen({
    super.key,
    this.patientId,
    this.initialApprovedByDoctor,
  });

  @override
  State<ExercisePlanListScreen> createState() => _ExercisePlanListScreenState();
}

class _ExercisePlanListScreenState extends State<ExercisePlanListScreen> {
  String search = '';
  ExercisePlanPhase? phaseFilter;
  ExercisePlanStatus? statusFilter;
  bool? approvedFilter;
  late Future<ExercisePlanListLoadResult> _loadFuture;
  ExercisePlanListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = ExercisePlanListRefresh.version;

  int get _planActiveFilterCount {
    var n = 0;
    if (phaseFilter != null) n++;
    if (statusFilter != null) n++;
    if (approvedFilter != null) n++;
    return n;
  }

  void _clearPlanFilters() {
    setState(() {
      phaseFilter = null;
      statusFilter = null;
      approvedFilter = null;
    });
    _reload();
  }

  @override
  void initState() {
    super.initState();
    approvedFilter = widget.initialApprovedByDoctor;
    _reload();
  }

  @override
  void activate() {
    super.activate();
    if (!_activatedOnce) {
      _activatedOnce = true;
      return;
    }
    if (ExercisePlanListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = ExercisePlanListRefresh.version;
    setState(() {
      _loadFuture = ExercisePlanListDataSource.load(
        patientId: widget.patientId,
        query: search,
        phaseFilter: phaseFilter,
        statusFilter: statusFilter,
        approvedByDoctor: approvedFilter,
      );
    });
  }

  Future<void> _openNew() async {
    final route = widget.patientId != null && widget.patientId!.isNotEmpty
        ? '/exercise-plans/new?patientId=${widget.patientId}'
        : '/exercise-plans/new';
    await context.push(route);
    if (mounted && ExercisePlanListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  Future<void> _openDetail(String id) async {
    await context.push('/exercise-plans/$id');
    if (mounted && ExercisePlanListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthSession.canEditExercisePlans;
    final title = widget.patientId != null && widget.patientId!.isNotEmpty
        ? 'Hasta Egzersiz Programları'
        : 'Egzersiz Programları';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.directions_run_outlined,
            ),
            FilterBar(
              searchHint:
                  'Hasta, plan, tanı özeti, hedef, faz veya duruma göre ara',
              onSearchChanged: (v) {
                search = v;
                _reload();
              },
              collapsible: _cachedResult != null,
              activeFilterCount: _planActiveFilterCount,
              onClearFilters:
                  _planActiveFilterCount > 0 ? _clearPlanFilters : null,
              trailing: canEdit
                  ? FilledButton.icon(
                      onPressed: _openNew,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Program'),
                    )
                  : null,
              filters: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<ExercisePlanPhase?>(
                    key: ValueKey('phase-${phaseFilter?.name ?? 'all'}'),
                    initialValue: phaseFilter,
                    decoration: const InputDecoration(
                      labelText: 'Faz',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm fazlar'),
                      ),
                      ...ExercisePlanPhase.values.map(
                        (ph) => DropdownMenuItem(
                          value: ph,
                          child: Text(exercisePlanPhaseLabel(ph)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => phaseFilter = v);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<ExercisePlanStatus?>(
                    key: ValueKey('status-${statusFilter?.name ?? 'all'}'),
                    initialValue: statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm durumlar'),
                      ),
                      ...ExercisePlanStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(exercisePlanStatusLabel(s)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => statusFilter = v);
                      _reload();
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Doktor onaylı'),
                  selected: approvedFilter == true,
                  onSelected: (selected) {
                    approvedFilter = selected ? true : null;
                    _reload();
                  },
                ),
                FilterChip(
                  label: const Text('Onay bekliyor'),
                  selected: approvedFilter == false,
                  onSelected: (selected) {
                    approvedFilter = selected ? false : null;
                    _reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildListBody(context, canEdit)),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(BuildContext context, bool canEdit) {
    return FutureBuilder<ExercisePlanListLoadResult>(
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
            message: 'Egzersiz programları yükleniyor...',
          );
        }

        if (snapshot.hasError && _cachedResult == null) {
          return _errorState('Egzersiz programları yüklenemedi.');
        }

        final active = result ?? _cachedResult;
        if (active == null) {
          return _errorState('Egzersiz programları yüklenemedi.');
        }

        if (active.hasError && _cachedResult == null) {
          return _errorState(
            active.errorMessage ?? 'Egzersiz programları yüklenemedi.',
          );
        }

        if (active.hasError && result != null) {
          return Column(
            children: [
              if (waiting) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _errorState(
                  active.errorMessage ?? 'Egzersiz programları yüklenemedi.',
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            if (waiting) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _listContent(context, active.plans, canEdit)),
          ],
        );
      },
    );
  }

  Widget _listContent(
    BuildContext context,
    List<ExercisePlan> list,
    bool canEdit,
  ) {
    if (list.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.fitness_center_outlined,
        title: 'Egzersiz programı bulunamadı',
        description: 'Arama veya filtre kriterlerinizi değiştirin.',
        action: canEdit
            ? OutlinedButton.icon(
                onPressed: _openNew,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Yeni Program'),
              )
            : null,
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final p in list) _buildCard(context, p),
      ],
    );
  }

  Widget _errorState(String message) {
    return ClinicalStateMessage.error(
      icon: Icons.error_outline,
      title: 'Egzersiz programları yüklenemedi',
      description: ClinicalStateMessage.safeErrorDescription(message),
      onRetry: _reload,
    );
  }

  Widget _buildCard(BuildContext context, ExercisePlan p) {
    final goal = p.goal.trim();
    final metaParts = <String>[
      exercisePlanPhaseLabel(p.phase),
      '${p.exercises.length} egzersiz',
      p.createdBy,
      if (goal.isNotEmpty) goal,
    ];

    return DataListCard(
      title: p.patientName,
      subtitle: p.title,
      metaLine: metaParts.join(' • '),
      trailing: _formatDate(p.createdAt),
      chips: [
        exercisePlanStatusLabel(p.status),
        p.doctorApproved ? 'Onaylandı' : 'Onay bekliyor',
      ],
      onTap: () => _openDetail(p.id),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
