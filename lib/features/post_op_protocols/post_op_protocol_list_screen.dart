import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/clinical_status_legend.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/post_op_protocol_list_data_source.dart';
import 'data/post_op_protocol_list_refresh.dart';
import 'models/post_op_protocol.dart';
import 'widgets/post_op_protocol_list_card.dart';
import 'widgets/post_op_protocol_list_filters_row.dart';
import 'widgets/post_op_protocol_list_legend.dart';

class PostOpProtocolListScreen extends StatefulWidget {
  final String? patientId;
  final String? surgeryNoteId;

  const PostOpProtocolListScreen({
    super.key,
    this.patientId,
    this.surgeryNoteId,
  });

  @override
  State<PostOpProtocolListScreen> createState() =>
      _PostOpProtocolListScreenState();
}

class _PostOpProtocolListScreenState extends State<PostOpProtocolListScreen> {
  String search = '';
  PostOpPhase? phaseFilter;
  PostOpProtocolStatus? statusFilter;
  late Future<PostOpProtocolListLoadResult> _loadFuture;
  PostOpProtocolListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PostOpProtocolListRefresh.version;

  int get _activeFilterCount {
    var n = 0;
    if (phaseFilter != null) n++;
    if (statusFilter != null) n++;
    return n;
  }

  void _clearFilters() {
    phaseFilter = null;
    statusFilter = null;
    _reload();
  }

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
    if (PostOpProtocolListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = PostOpProtocolListRefresh.version;
    setState(() {
      _loadFuture = PostOpProtocolListDataSource.load(
        patientId: widget.patientId,
        surgeryNoteId: widget.surgeryNoteId,
        query: search,
        phaseFilter: phaseFilter,
        statusFilter: statusFilter,
      );
    });
  }

  Future<void> _openNew() async {
    final parts = <String>[];
    if (widget.patientId != null && widget.patientId!.isNotEmpty) {
      parts.add('patientId=${widget.patientId}');
    }
    if (widget.surgeryNoteId != null && widget.surgeryNoteId!.isNotEmpty) {
      parts.add('surgeryNoteId=${widget.surgeryNoteId}');
    }
    final query = parts.isEmpty ? '' : '?${parts.join('&')}';
    await context.push('/post-op-protocols/new$query');
    if (mounted && PostOpProtocolListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  Future<void> _openDetail(String id) async {
    await context.push('/post-op-protocols/$id');
    if (mounted && PostOpProtocolListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthSession.canEditPostOpProtocols;

    return AppShell(
      title: 'Post-op Takip',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Post-op Takip',
              icon: Icons.assignment_turned_in_outlined,
            ),
            FilterBar(
              searchHint:
                  'Hasta, protokol, faz, durum veya işlem/tanı özetine göre ara',
              onSearchChanged: (v) {
                search = v;
                _reload();
              },
              collapsible: _cachedResult != null,
              activeFilterCount: _activeFilterCount,
              onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              trailing: canEdit
                  ? FilledButton.icon(
                      onPressed: _openNew,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Protokol'),
                    )
                  : null,
              filters: [
                PostOpProtocolListFiltersRow(
                  phaseFilter: phaseFilter,
                  statusFilter: statusFilter,
                  onPhaseChanged: (v) {
                    phaseFilter = v;
                    _reload();
                  },
                  onStatusChanged: (v) {
                    statusFilter = v;
                    _reload();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildAsyncListBody(context, canEdit)),
          ],
        ),
      ),
    );
  }

  Widget _buildAsyncListBody(BuildContext context, bool canEdit) {
    return FutureBuilder<PostOpProtocolListLoadResult>(
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
            message: 'Post-op protokoller yükleniyor...',
          );
        }

        if (snapshot.hasError && _cachedResult == null) {
          return _errorState('Post-op protokoller yüklenemedi.');
        }

        final active = result ?? _cachedResult;
        if (active == null) {
          return _errorState('Post-op protokoller yüklenemedi.');
        }

        if (active.hasError) {
          return _errorState(
            active.errorMessage ?? 'Post-op protokoller yüklenemedi.',
          );
        }

        return Column(
          children: [
            if (waiting) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildListBody(context, active.protocols, canEdit)),
          ],
        );
      },
    );
  }

  Widget _buildListBody(
    BuildContext context,
    List<PostOpProtocol> list,
    bool canEdit,
  ) {
    if (list.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Post-op protokol bulunamadı',
        description: 'Arama veya filtre kriterlerinizi değiştirin.',
        action: canEdit
            ? OutlinedButton.icon(
                onPressed: _openNew,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Yeni Protokol'),
              )
            : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final protocol = list[index];
              return PostOpProtocolListCard(
                protocol: protocol,
                onTap: () => _openDetail(protocol.id),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const ClinicalStatusLegend(
          items: PostOpProtocolListLegend.items,
        ),
      ],
    );
  }

  Widget _errorState(String message) {
    return ClinicalStateMessage.error(
      icon: Icons.error_outline,
      title: 'Post-op protokoller yüklenemedi',
      description: ClinicalStateMessage.safeErrorDescription(message),
      onRetry: _reload,
    );
  }
}
