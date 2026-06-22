import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/data_list_card.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/page_header.dart';
import 'data/imaging_list_data_source.dart';
import 'data/imaging_list_refresh.dart';
import 'data/imaging_repository.dart';
import 'models/imaging_note.dart';

class ImagingListScreen extends StatefulWidget {
  final String? patientId;
  const ImagingListScreen({super.key, this.patientId});

  @override
  State<ImagingListScreen> createState() => _ImagingListScreenState();
}

class _ImagingListScreenState extends State<ImagingListScreen> {
  String q = '';
  ImagingType? typeFilter;
  ImagingBodyRegion? regionFilter;
  late Future<ImagingListLoadResult> _loadFuture;
  ImagingListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = ImagingListRefresh.version;

  int get _activeFilterCount {
    var n = 0;
    if (typeFilter != null) n++;
    if (regionFilter != null) n++;
    return n;
  }

  void _clearFilters() {
    setState(() {
      typeFilter = null;
      regionFilter = null;
    });
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
    if (ImagingListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = ImagingListRefresh.version;
    setState(() {
      _loadFuture = ImagingListDataSource.load(
        patientId: widget.patientId,
        query: q,
        imagingTypeFilter: typeFilter,
        bodyRegionFilter: regionFilter,
      );
    });
  }

  Future<void> _openNew() async {
    final route = widget.patientId != null && widget.patientId!.isNotEmpty
        ? '/imaging/new?patientId=${widget.patientId}'
        : '/imaging/new';
    await context.push(route);
    if (mounted && ImagingListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  Future<void> _openDetail(String id) async {
    await context.push('/imaging/$id');
    if (mounted && ImagingListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = widget.patientId != null && widget.patientId!.isNotEmpty
        ? 'Hasta Görüntüleme Notları'
        : 'Görüntüleme Notları';

    return AppShell(
      title: 'Görüntüleme Notları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: headerTitle,
              icon: Icons.image_outlined,
            ),
            FilterBar(
              searchHint: 'Hasta, tip, bölge, rapor veya yorum ara',
              onSearchChanged: (v) {
                q = v;
                _reload();
              },
              collapsible: _cachedResult != null,
              activeFilterCount: _activeFilterCount,
              onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              trailing: FilledButton.icon(
                onPressed: _openNew,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Görüntüleme Notu'),
              ),
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<ImagingType?>(
                      label: 'Görüntüleme tipi',
                      value: typeFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm tipler'),
                        ),
                        ...ImagingType.values.map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(ImagingRepository.typeLabel(t)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => typeFilter = v);
                        _reload();
                      },
                    ),
                    ListFiltersRow.dropdown<ImagingBodyRegion?>(
                      label: 'Bölge',
                      value: regionFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tüm bölgeler'),
                        ),
                        ...ImagingBodyRegion.values.map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(ImagingRepository.regionLabel(r)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => regionFilter = v);
                        _reload();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildListBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(BuildContext context) {
    return FutureBuilder<ImagingListLoadResult>(
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
            message: 'Görüntüleme notları yükleniyor...',
          );
        }

        if (snapshot.hasError && _cachedResult == null) {
          return _errorState('Görüntüleme notları yüklenemedi.');
        }

        final active = result ?? _cachedResult;
        if (active == null) {
          return _errorState('Görüntüleme notları yüklenemedi.');
        }

        if (active.hasError && _cachedResult == null) {
          return _errorState(active.errorMessage ?? 'Görüntüleme notları yüklenemedi.');
        }

        if (active.hasError && result != null) {
          return Column(
            children: [
              if (waiting) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _errorState(
                  active.errorMessage ?? 'Görüntüleme notları yüklenemedi.',
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            if (waiting) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _listContent(context, active.notes)),
          ],
        );
      },
    );
  }

  Widget _listContent(BuildContext context, List<ImagingNote> list) {
    if (list.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.image_search_outlined,
        title: 'Görüntüleme notu bulunamadı',
        description: 'Arama veya filtre kriterlerinizi değiştirin.',
        action: OutlinedButton.icon(
          onPressed: _openNew,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Yeni Görüntüleme Notu'),
        ),
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final n in list) _buildCard(context, n),
      ],
    );
  }

  Widget _errorState(String message) {
    return ClinicalStateMessage.error(
      icon: Icons.error_outline,
      title: 'Görüntüleme notları yüklenemedi',
      description: ClinicalStateMessage.safeErrorDescription(message),
      onRetry: _reload,
    );
  }

  Widget _buildCard(BuildContext context, ImagingNote n) {
    final summary = n.reportSummary.trim();
    final file = n.attachedFileName?.trim() ?? '';
    final metaParts = <String>[
      ImagingRepository.regionLabel(n.bodyRegion),
      if (summary.isNotEmpty) summary,
      if (file.isNotEmpty) 'Dosya: $file',
    ];
    final metaLine = metaParts.join(' • ');

    final chips = <String>[
      imagingSideLabel(n.side),
      if (n.doctorComment.trim().isNotEmpty) 'Yorum var',
    ];

    return DataListCard(
      title: n.patientName,
      subtitle: ImagingRepository.typeLabel(n.imagingType),
      metaLine: metaLine,
      trailing: _formatDate(n.imagingDate),
      chips: chips,
      onTap: () => _openDetail(n.id),
    );
  }
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  return '$d.$m.${local.year}';
}
