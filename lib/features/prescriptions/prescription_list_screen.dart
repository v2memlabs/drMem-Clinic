import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/page_header.dart';
import 'data/prescription_list_data_source.dart';
import 'data/prescription_list_load_result.dart';
import 'data/prescription_list_refresh.dart';
import 'data/prescription_user_messages.dart';
import 'models/prescription.dart';
import 'widgets/prescription_list_row.dart';

class PrescriptionListScreen extends StatefulWidget {
  final String? patientId;

  const PrescriptionListScreen({super.key, this.patientId});

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  String _query = '';
  PrescriptionStatus? _statusFilter;
  late Future<PrescriptionListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PrescriptionListRefresh.version;

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
    if (PrescriptionListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = PrescriptionListRefresh.version;
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _loadFuture = PrescriptionListDataSource.load(
        patientId: widget.patientId,
        query: _query,
        statusFilter: _statusFilter,
      );
    });
  }

  Future<void> _openDetail(String id) async {
    await context.push('/prescriptions/$id');
    if (mounted && PrescriptionListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = PrescriptionListRefresh.version;
      _reload();
    }
  }

  Future<void> _openNew() async {
    final q = widget.patientId != null ? '?patientId=${widget.patientId}' : '';
    await context.push('/prescriptions/new$q');
    if (mounted && PrescriptionListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = PrescriptionListRefresh.version;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.patientId != null && widget.patientId!.isNotEmpty
        ? 'Hasta Reçeteleri'
        : 'Reçeteler';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.medication_outlined,
              leadingBack: widget.patientId != null,
              fallbackRoute: '/prescriptions',
            ),
            FilterBar(
              searchHint: 'Hasta, tanı veya ilaç ara',
              onSearchChanged: (v) {
                _query = v;
                _reload();
              },
              collapsible: true,
              activeFilterCount: _statusFilter != null ? 1 : 0,
              onClearFilters: _statusFilter != null
                  ? () {
                      _statusFilter = null;
                      _reload();
                    }
                  : null,
              trailing: FilledButton.icon(
                onPressed: _openNew,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Reçete'),
              ),
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<PrescriptionStatus?>(
                      label: 'Durum',
                      value: _statusFilter,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text(
                            'Tüm durumlar',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...PrescriptionStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              prescriptionStatusLabel(s),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        _statusFilter = v;
                        _reload();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<PrescriptionListLoadResult>(
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
                      title: 'Reçeteler yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        result?.errorMessage ??
                            PrescriptionUserMessages.genericLoadFailure,
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

  Widget _buildListBody(List<Prescription> items) {
    if (items.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.medication_outlined,
        title: 'Reçete kaydı bulunamadı',
        description: 'Yeni reçete oluşturmak için üstteki butonu kullanın.',
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final item in items)
          PrescriptionListRow(
            prescription: item,
            onTap: () => _openDetail(item.id),
          ),
      ],
    );
  }
}
