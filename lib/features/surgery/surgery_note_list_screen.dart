import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/clinical_status_legend.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/page_header.dart';
import 'data/surgery_note_list_data_source.dart';
import 'data/surgery_note_list_load_result.dart';
import 'data/surgery_note_list_refresh.dart';
import 'models/surgery_procedure_note.dart';
import 'widgets/surgery_procedure_clinical_list_row.dart';
import 'widgets/surgery_procedure_list_legend.dart';

class SurgeryNoteListScreen extends StatefulWidget {
  final String? patientId;

  const SurgeryNoteListScreen({super.key, this.patientId});

  @override
  State<SurgeryNoteListScreen> createState() => _SurgeryNoteListScreenState();
}

class _SurgeryNoteListScreenState extends State<SurgeryNoteListScreen> {
  String _search = '';
  ProcedureType? _typeFilter;
  SurgeryBodyRegion? _regionFilter;
  late Future<SurgeryNoteListLoadResult> _loadFuture;
  SurgeryNoteListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = SurgeryNoteListRefresh.version;

  int get _activeFilterCount {
    var n = 0;
    if (_typeFilter != null) n++;
    if (_regionFilter != null) n++;
    return n;
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
    if (SurgeryNoteListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = SurgeryNoteListRefresh.version;
    setState(() {
      _loadFuture = SurgeryNoteListDataSource.load(
        patientId: widget.patientId,
        query: _search,
        procedureTypeFilter: _typeFilter,
        bodyRegionFilter: _regionFilter,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _typeFilter = null;
      _regionFilter = null;
    });
    _reload();
  }

  void _openNew() {
    final route = widget.patientId != null && widget.patientId!.isNotEmpty
        ? '/surgery-notes/new?patientId=${widget.patientId}'
        : '/surgery-notes/new';
    context.push(route);
  }

  Future<void> _openDetail(String id) async {
    await context.push('/surgery-notes/$id');
    if (mounted && SurgeryNoteListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Ameliyat / Girişim Notları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'Ameliyat / Girişim Notları',
              icon: Icons.medical_services_outlined,
            ),
            FilterBar(
              searchHint:
                  'Hasta, işlem, bölge, işlem tipi veya tanıya göre ara',
              onSearchChanged: (v) {
                _search = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _activeFilterCount,
              onClearFilters: _activeFilterCount > 0 ? _clearFilters : null,
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/surgery-note-templates'),
                    icon: const Icon(Icons.library_books_outlined, size: 18),
                    label: const Text('Şablonlarım'),
                  ),
                  FilledButton.icon(
                    onPressed: _openNew,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Yeni Not'),
                  ),
                ],
              ),
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<ProcedureType?>(
                      label: 'İşlem tipi',
                      value: _typeFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Tüm işlem tipleri',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...ProcedureType.values.map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(procedureTypeLabel(t)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _typeFilter = v);
                        _reload();
                      },
                    ),
                    ListFiltersRow.dropdown<SurgeryBodyRegion?>(
                      label: 'Bölge',
                      value: _regionFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Tüm bölgeler',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...SurgeryBodyRegion.values.map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(surgeryBodyRegionLabel(r)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _regionFilter = v);
                        _reload();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<SurgeryNoteListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _cachedResult == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final result = snapshot.data ?? _cachedResult;
                  if (snapshot.hasData) {
                    _cachedResult = snapshot.data;
                  }

                  if (result == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (result.hasError) {
                    return ClinicalStateMessage.error(
                      icon: Icons.error_outline,
                      title: 'Liste yüklenemedi',
                      description: result.errorMessage!,
                      onRetry: _reload,
                    );
                  }

                  return _buildListBody(context, result.notes);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(BuildContext context, List<SurgeryProcedureNote> list) {
    if (list.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.medical_services_outlined,
        title: 'Kayıt bulunamadı',
        description: 'Arama veya filtre kriterlerinizi değiştirin.',
        action: OutlinedButton.icon(
          onPressed: _openNew,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Yeni Not'),
        ),
      );
    }

    return ClinicalSeparatedListBody(
      legend: ClinicalStatusLegend(
        title: 'İşlem renkleri',
        items: SurgeryProcedureListLegend.items,
      ),
      children: [
        for (final n in list)
          SurgeryProcedureClinicalListRow(
            note: n,
            onTap: () => _openDetail(n.id),
          ),
      ],
    );
  }
}
