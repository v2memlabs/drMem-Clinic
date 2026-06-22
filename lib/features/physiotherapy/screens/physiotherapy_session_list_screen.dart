import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/layout/responsive_page_body.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/clinical_state_message.dart';
import '../../../shared/widgets/data_list_card.dart';
import '../../../shared/widgets/clinical_separated_list_body.dart';
import '../../../shared/widgets/filter_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../data/physiotherapy_session_list_data_source.dart';
import '../data/physiotherapy_session_list_load_result.dart';
import '../data/physiotherapy_session_list_refresh.dart';
import '../data/physiotherapy_session_user_messages.dart';
import '../models/physiotherapy_session_note.dart';

class PhysiotherapySessionListScreen extends StatefulWidget {
  final String? patientId;

  const PhysiotherapySessionListScreen({super.key, this.patientId});

  @override
  State<PhysiotherapySessionListScreen> createState() =>
      _PhysiotherapySessionListScreenState();
}

class _PhysiotherapySessionListScreenState
    extends State<PhysiotherapySessionListScreen> {
  String search = '';
  ReturnToSportStage? stageFilter;
  bool? doctorNotificationFilter;
  late Future<PhysiotherapySessionListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PhysiotherapySessionListRefresh.version;

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
    if (PhysiotherapySessionListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = PhysiotherapySessionListRefresh.version;
    setState(() {
      _loadFuture = PhysiotherapySessionListDataSource.load(
        patientId: widget.patientId,
        query: search,
        returnToSportStageEnumFilter: stageFilter,
        doctorNotificationNeeded: doctorNotificationFilter,
      );
    });
  }

  int get _sessionActiveFilterCount {
    var n = 0;
    if (stageFilter != null) n++;
    if (doctorNotificationFilter != null) n++;
    return n;
  }

  void _clearSessionFilters() {
    setState(() {
      stageFilter = null;
      doctorNotificationFilter = null;
    });
    _reload();
  }

  Future<void> _openDetail(String id) async {
    await context.push('/physiotherapy/sessions/$id');
    if (mounted &&
        PhysiotherapySessionListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  String _newSessionRoute() {
    final pid = widget.patientId?.trim();
    if (pid != null && pid.isNotEmpty) {
      return '/physiotherapy/sessions/new?patientId=$pid';
    }
    return '/physiotherapy/sessions/new';
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthSession.canEditPhysiotherapy;
    final title = widget.patientId != null && widget.patientId!.isNotEmpty
        ? 'Hasta Seans Notları'
        : 'Fizyoterapi Seans Notları';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.fitness_center_outlined,
            ),
            FilterBar(
              searchHint:
                  'Hasta, fizyoterapist, spora dönüş aşaması veya notlara göre ara',
              onSearchChanged: (v) {
                search = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _sessionActiveFilterCount,
              onClearFilters:
                  _sessionActiveFilterCount > 0 ? _clearSessionFilters : null,
              trailing: canEdit
                  ? FilledButton.icon(
                      onPressed: () => context.push(_newSessionRoute()),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Seans'),
                    )
                  : null,
              filters: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<ReturnToSportStage?>(
                    value: stageFilter,
                    decoration: const InputDecoration(
                      labelText: 'Spora dönüş aşaması',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm aşamalar'),
                      ),
                      ...ReturnToSportStage.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(returnToSportStageLabel(s)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => stageFilter = v);
                      _reload();
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Doktor bildirimi gerekli'),
                  selected: doctorNotificationFilter == true,
                  onSelected: (selected) {
                    setState(() {
                      doctorNotificationFilter = selected ? true : null;
                    });
                    _reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<PhysiotherapySessionListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ClinicalStateMessage.loading(
                      message: PhysiotherapySessionListUserMessages.loading,
                    );
                  }

                  final result = snapshot.data!;
                  if (result.hasError) {
                    return ClinicalStateMessage.error(
                      icon: Icons.error_outline,
                      title: PhysiotherapySessionListUserMessages.errorTitle,
                      description: result.errorMessage!,
                      onRetry: _reload,
                    );
                  }

                  final list = result.items ?? const [];

                  if (list.isEmpty) {
                    return ClinicalStateMessage.empty(
                      icon: Icons.event_note_outlined,
                      title: 'Seans notu bulunamadı',
                      description:
                          'Arama veya filtre kriterlerinizi değiştirin.',
                      action: canEdit
                          ? OutlinedButton.icon(
                              onPressed: () => context.push(_newSessionRoute()),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Yeni Seans'),
                            )
                          : null,
                    );
                  }

                  return ClinicalSeparatedListBody(
                    children: [
                      for (final s in list) _buildCard(context, s),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, PhysiotherapySessionNote s) {
    final chips = <String>[s.returnToSportLabel];
    if (s.doctorNotificationNeeded) chips.add('Doktor bildirimi');

    final exercise = s.exercisesPerformed.trim();
    final subtitle = exercise.isNotEmpty
        ? exercise
        : (s.functionalAssessment.trim().isNotEmpty
            ? s.functionalAssessment.trim()
            : null);

    return DataListCard(
      title: s.patientName,
      subtitle: subtitle,
      metaLine: 'Ağrı: ${s.painScore}/10 • ${s.physiotherapistName}',
      trailing: _formatDate(s.sessionDate),
      chips: chips,
      onTap: () => _openDetail(s.id),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
