import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/clinical_report_list_data_source.dart';
import 'data/clinical_report_list_load_result.dart';
import 'data/clinical_report_list_refresh.dart';
import 'data/clinical_report_user_messages.dart';
import 'models/clinical_report.dart';
import 'widgets/clinical_report_list_row.dart';

class ClinicalReportListScreen extends StatefulWidget {
  final String? patientId;

  const ClinicalReportListScreen({super.key, this.patientId});

  @override
  State<ClinicalReportListScreen> createState() =>
      _ClinicalReportListScreenState();
}

class _ClinicalReportListScreenState extends State<ClinicalReportListScreen> {
  String _query = '';
  ClinicalReportType? _typeFilter;
  late Future<ClinicalReportListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = ClinicalReportListRefresh.version;

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
    if (ClinicalReportListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = ClinicalReportListRefresh.version;
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _loadFuture = ClinicalReportListDataSource.load(
        patientId: widget.patientId,
        query: _query,
        typeFilter: _typeFilter,
      );
    });
  }

  Future<void> _openDetail(String id) async {
    await context.push('/clinical-reports/$id');
    if (mounted && ClinicalReportListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = ClinicalReportListRefresh.version;
      _reload();
    }
  }

  Future<void> _openNew() async {
    final q = widget.patientId != null ? '?patientId=${widget.patientId}' : '';
    await context.push('/clinical-reports/new$q');
    if (mounted && ClinicalReportListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = ClinicalReportListRefresh.version;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.patientId != null && widget.patientId!.isNotEmpty
        ? 'Hasta Raporları'
        : 'Raporlar';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.description_outlined,
              leadingBack: widget.patientId != null,
              fallbackRoute: '/clinical-reports',
            ),
            FilterBar(
              searchHint: 'Hasta, tanı veya rapor tipi ara',
              onSearchChanged: (v) {
                _query = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _typeFilter != null ? 1 : 0,
              onClearFilters: _typeFilter != null
                  ? () {
                      _typeFilter = null;
                      _reload();
                    }
                  : null,
              trailing: AuthSession.canEditClinicalReports
                  ? FilledButton.icon(
                      onPressed: _openNew,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Rapor'),
                    )
                  : null,
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<ClinicalReportType?>(
                      label: 'Rapor tipi',
                      value: _typeFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Tüm rapor tipleri',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...ClinicalReportType.values.map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              clinicalReportTypeLabel(t),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        _typeFilter = v;
                        _reload();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<ClinicalReportListLoadResult>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  final result = snapshot.data;
                  if (snapshot.hasError || result == null || result.hasError) {
                    return ClinicalStateMessage.error(
                      icon: Icons.error_outline,
                      title: 'Raporlar yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        result?.errorMessage ??
                            ClinicalReportUserMessages.genericLoadFailure,
                      ),
                      onRetry: _reload,
                    );
                  }

                  return _buildListBody(result.items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(List<ClinicalReport> items) {
    if (items.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.description_outlined,
        title: 'Rapor kaydı bulunamadı',
        description: AuthSession.canEditClinicalReports
            ? 'İstirahat, durum bildirir, uçabilir veya cihaz kullanım raporu oluşturun.'
            : 'Kayıtlı klinik rapor bulunmuyor.',
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final item in items)
          ClinicalReportListRow(
            report: item,
            onTap: () => _openDetail(item.id),
          ),
      ],
    );
  }
}
