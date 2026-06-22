import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_status_legend.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/consent_list_data_source.dart';
import 'data/consent_list_load_result.dart';
import 'data/consent_list_refresh.dart';
import 'data/consent_list_user_messages.dart';
import 'data/consent_repository_provider.dart';
import 'models/consent_record.dart';
import 'widgets/consent_clinical_list_row.dart';
import 'widgets/consent_list_legend.dart';

class ConsentListScreen extends StatefulWidget {
  final String? patientId;
  const ConsentListScreen({super.key, this.patientId});

  @override
  State<ConsentListScreen> createState() => _ConsentListScreenState();
}

class _ConsentListScreenState extends State<ConsentListScreen> {
  String _query = '';
  ConsentType? _typeFilter;
  ConsentStatus? _statusFilter;
  late Future<ConsentListLoadResult> _loadFuture;
  ConsentListLoadResult? _cachedResult;
  bool _activatedOnce = false;
  int _lastRefreshVersion = ConsentListRefresh.version;

  int get _consentActiveFilterCount {
    var n = 0;
    if (_typeFilter != null) n++;
    if (_statusFilter != null) n++;
    return n;
  }

  void _clearConsentFilters() {
    setState(() {
      _typeFilter = null;
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
    if (ConsentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    ConsentRepositoryProvider.resetCache();
    _lastRefreshVersion = ConsentListRefresh.version;
    setState(() {
      _loadFuture = ConsentListDataSource.load(
        patientId: widget.patientId,
        query: _query,
        consentTypeFilter: _typeFilter,
        statusFilter: _statusFilter,
      );
    });
  }

  Future<void> _openConsentDetail(String id) async {
    await context.push('/consents/$id');
    if (mounted && ConsentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  Future<void> _openNewConsent() async {
    await context.push(
      '/consents/new${widget.patientId != null ? '?patientId=${widget.patientId}' : ''}',
    );
    if (mounted && ConsentListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.patientId != null && widget.patientId!.isNotEmpty
        ? 'Hasta Onam Kayıtları'
        : 'KVKK / Onam Takibi';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.privacy_tip_outlined,
            ),
            FilterBar(
              searchHint: 'Hasta, onam tipi veya belge ara',
              onSearchChanged: (v) {
                _query = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _consentActiveFilterCount,
              onClearFilters:
                  _consentActiveFilterCount > 0 ? _clearConsentFilters : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (AuthSession.canViewConsentTemplates)
                    OutlinedButton.icon(
                      onPressed: () => context.push('/consent-templates'),
                      icon: const Icon(Icons.description_outlined),
                      label: const Text('Şablonlar'),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _openNewConsent,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Onam Evrakı'),
                  ),
                ],
              ),
              filters: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<ConsentType?>(
                    value: _typeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Onam tipi',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tüm onam tipleri'),
                      ),
                      ...ConsentType.values.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(consentTypeLabel(t)),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _typeFilter = v);
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<ConsentStatus?>(
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
                      ...ConsentStatus.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(consentStatusLabel(s)),
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
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<ConsentListLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final result = snapshot.data;

        if (waiting && _cachedResult == null) {
          return ClinicalStateMessage.loading(
            message: ConsentListUserMessages.loading,
          );
        }

        if (result != null && !result.hasError) {
          _cachedResult = result;
        }

        final active = result ?? _cachedResult;
        if (active == null) {
          return ClinicalStateMessage.loading(
            message: ConsentListUserMessages.loading,
          );
        }

        if (active.hasError) {
          return ClinicalStateMessage.error(
            icon: Icons.error_outline,
            title: ConsentListUserMessages.errorTitle,
            description: ClinicalStateMessage.safeErrorDescription(
              active.errorMessage,
            ),
            onRetry: _reload,
          );
        }

        final list = active.records;
        if (list.isEmpty) {
          return ClinicalStateMessage.empty(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Onam kaydı bulunamadı',
            description: 'Arama veya filtre kriterlerinizi değiştirin.',
          );
        }

        return ClinicalSeparatedListBody(
          legend: const ClinicalStatusLegend(
            items: ConsentListLegend.items,
          ),
          children: [
            for (final c in list)
              ConsentClinicalListRow(
                record: c,
                onTap: () => _openConsentDetail(c.id),
              ),
          ],
        );
      },
    );
  }
}
