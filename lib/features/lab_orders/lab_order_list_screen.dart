import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_separated_list_body.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/filter_bar.dart';
import '../../shared/widgets/list_filters_row.dart';
import '../../shared/widgets/page_header.dart';
import 'data/lab_order_list_data_source.dart';
import 'data/lab_order_list_load_result.dart';
import 'data/lab_order_list_refresh.dart';
import 'data/lab_order_user_messages.dart';
import 'models/lab_order.dart';
import 'widgets/lab_order_list_row.dart';

class LabOrderListScreen extends StatefulWidget {
  final String? patientId;
  const LabOrderListScreen({super.key, this.patientId});

  @override
  State<LabOrderListScreen> createState() => _LabOrderListScreenState();
}

class _LabOrderListScreenState extends State<LabOrderListScreen> {
  String _query = '';
  LabOrderStatus? _statusFilter;
  late Future<LabOrderListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = LabOrderListRefresh.version;

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
    if (LabOrderListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = LabOrderListRefresh.version;
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _loadFuture = LabOrderListDataSource.load(
        patientId: widget.patientId,
        query: _query,
        statusFilter: _statusFilter,
      );
    });
  }

  Future<void> _openDetail(String id) async {
    await context.push('/lab-orders/$id');
    if (mounted && LabOrderListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = LabOrderListRefresh.version;
      _reload();
    }
  }

  Future<void> _openNew() async {
    final patientQ =
        widget.patientId != null ? '?patientId=${widget.patientId}' : '';
    await context.push('/lab-orders/new$patientQ');
    if (mounted && LabOrderListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = LabOrderListRefresh.version;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.patientId != null
        ? 'Hasta Laboratuvar İstemleri'
        : 'Laboratuvar İstemleri';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.biotech_outlined,
              leadingBack: widget.patientId != null,
              fallbackRoute: '/lab-orders',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/lab-order-templates'),
                  icon: const Icon(Icons.library_books_outlined, size: 18),
                  label: const Text('Şablonlar'),
                ),
              ],
            ),
            FilterBar(
              searchHint: 'Hasta, tanı veya tahlil ara',
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
                label: const Text('Yeni İstem'),
              ),
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<LabOrderStatus?>(
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
                        ...LabOrderStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              labOrderStatusLabel(s),
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
              child: FutureBuilder<LabOrderListLoadResult>(
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
                      title: 'Laboratuvar istemleri yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        result?.errorMessage ??
                            LabOrderUserMessages.genericLoadFailure,
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

  Widget _buildListBody(List<LabOrder> items) {
    if (items.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.biotech_outlined,
        title: 'Laboratuvar istemi bulunamadı',
        description: 'Preoperatif, enfeksiyon veya EKG paneli istemi oluşturun.',
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final item in items)
          LabOrderListRow(
            order: item,
            onTap: () => _openDetail(item.id),
          ),
      ],
    );
  }
}
