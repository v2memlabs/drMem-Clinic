import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/data/repository_registry.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import 'widgets/pdf_output_clinical_list_row.dart';
import 'data/pdf_output_list_data_source.dart';
import 'data/pdf_output_list_load_result.dart';
import 'data/pdf_output_list_refresh.dart';
import 'data/pdf_output_list_user_messages.dart';
import 'models/pdf_output.dart';

class PdfOutputListScreen extends StatefulWidget {
  final String? patientId;
  const PdfOutputListScreen({super.key, this.patientId});

  @override
  State<PdfOutputListScreen> createState() => _PdfOutputListScreenState();
}

class _PdfOutputListScreenState extends State<PdfOutputListScreen> {
  String _search = '';
  DocumentType? _docFilter;
  PdfStatus? _statusFilter;
  late Future<PdfOutputListLoadResult> _loadFuture;
  Timer? _searchDebounce;
  PdfOutputListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PdfOutputListRefresh.version;

  static const Duration _remoteSearchDebounce = Duration(milliseconds: 350);

  bool get _usesRemote => RepositoryRegistry.usesRemotePdfOutputs;

  bool get _hasPatientFilter =>
      widget.patientId != null && widget.patientId!.isNotEmpty;

  int get _pdfActiveFilterCount {
    var n = 0;
    if (_docFilter != null) n++;
    if (_statusFilter != null) n++;
    return n;
  }

  void _clearPdfFilters() {
    setState(() {
      _docFilter = null;
      _statusFilter = null;
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
    if (PdfOutputListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _reload() {
    _lastRefreshVersion = PdfOutputListRefresh.version;
    setState(() {
      _loadFuture = PdfOutputListDataSource.load(
        patientId: widget.patientId,
        query: _search,
        documentTypeFilter: _docFilter,
        statusFilter: _statusFilter,
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

  Future<void> _openOutput(String id) async {
    await context.push('/pdf-outputs/$id');
    if (mounted && PdfOutputListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  Future<void> _openNewOutput() async {
    final route = _hasPatientFilter
        ? '/pdf-outputs/new?patientId=${widget.patientId}'
        : '/pdf-outputs/new';
    await context.push(route);
    if (mounted && PdfOutputListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = AuthSession.canEditPdfOutputs;

    return AppShell(
      title: 'PDF Hasta Bilgilendirme Çıktıları',
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: 'PDF Çıktılar',
              icon: Icons.picture_as_pdf_outlined,
            ),
            FilterBar(
              searchHint: 'Hasta, başlık, belge tipi veya oluşturan ara',
              onSearchChanged: _onSearchChanged,
              collapsible: true,
              activeFilterCount: _pdfActiveFilterCount,
              onClearFilters:
                  _pdfActiveFilterCount > 0 ? _clearPdfFilters : null,
              trailing: canEdit
                  ? FilledButton.icon(
                      onPressed: _openNewOutput,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni PDF Çıktı'),
                    )
                  : null,
              filters: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<DocumentType?>(
                    value: _docFilter,
                    decoration: const InputDecoration(
                      labelText: 'Belge tipi',
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm belge tipleri'),
                      ),
                      ...DocumentType.values.map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            documentTypeLabel(d),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _docFilter = v);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<PdfStatus?>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm durumlar'),
                      ),
                      ...PdfStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            pdfStatusLabel(s),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _statusFilter = v);
                      _reload();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<PdfOutputListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  final waiting =
                      snapshot.connectionState == ConnectionState.waiting;
                  final result = snapshot.data;
                  if (result != null && !result.hasError) {
                    _cachedResult = result;
                  }
                  final active = result ?? _cachedResult;

                  if (waiting && active == null) {
                    return ClinicalStateMessage.loading(
                      message: PdfOutputListUserMessages.loading,
                    );
                  }

                  if (active != null && active.hasError) {
                    return ClinicalStateMessage.error(
                      icon: Icons.error_outline,
                      title: 'PDF çıktıları yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        active.errorMessage,
                      ),
                      onRetry: _reload,
                    );
                  }

                  final list = active?.outputs ?? const <PdfOutput>[];

                  if (list.isEmpty) {
                    return ClinicalStateMessage.empty(
                      icon: Icons.picture_as_pdf_outlined,
                      title: PdfOutputListUserMessages.emptyGeneric,
                      description: PdfOutputListUserMessages.emptyDescription,
                      action: canEdit
                          ? OutlinedButton.icon(
                              onPressed: _openNewOutput,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Yeni PDF Çıktı'),
                            )
                          : null,
                    );
                  }

                  return ClinicalSeparatedListBody(
                    children: [
                      for (final output in list)
                        PdfOutputClinicalListRow(
                          output: output,
                          onTap: () => _openOutput(output.id),
                        ),
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
}
