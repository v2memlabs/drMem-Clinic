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
import 'data/radiology_order_list_data_source.dart';
import 'data/radiology_order_list_load_result.dart';
import 'data/radiology_order_list_refresh.dart';
import 'data/radiology_order_user_messages.dart';
import 'models/radiology_order.dart';
import 'widgets/radiology_order_list_row.dart';

class RadiologyOrderListScreen extends StatefulWidget {
  final String? patientId;
  const RadiologyOrderListScreen({super.key, this.patientId});

  @override
  State<RadiologyOrderListScreen> createState() =>
      _RadiologyOrderListScreenState();
}

class _RadiologyOrderListScreenState extends State<RadiologyOrderListScreen> {
  String _query = '';
  RadiologyOrderStatus? _statusFilter;
  late Future<RadiologyOrderListLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = RadiologyOrderListRefresh.version;

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
    if (RadiologyOrderListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = RadiologyOrderListRefresh.version;
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _loadFuture = RadiologyOrderListDataSource.load(
        patientId: widget.patientId,
        query: _query,
        statusFilter: _statusFilter,
      );
    });
  }

  Future<void> _openDetail(String id) async {
    await context.push('/radiology-orders/$id');
    if (mounted && RadiologyOrderListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = RadiologyOrderListRefresh.version;
      _reload();
    }
  }

  Future<void> _openNew() async {
    final q = widget.patientId != null ? '?patientId=${widget.patientId}' : '';
    await context.push('/radiology-orders/new$q');
    if (mounted && RadiologyOrderListRefresh.isStale(_lastRefreshVersion)) {
      _lastRefreshVersion = RadiologyOrderListRefresh.version;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.patientId != null
        ? 'Hasta Radyoloji İstemleri'
        : 'Radyoloji İstemleri';

    return AppShell(
      title: title,
      child: ResponsiveListPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: title,
              icon: Icons.radar_outlined,
              leadingBack: widget.patientId != null,
              fallbackRoute: '/radiology-orders',
            ),
            FilterBar(
              searchHint: 'Hasta, tanı veya modalite ara',
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
              trailing: AuthSession.canEditRadiologyOrders
                  ? FilledButton.icon(
                      onPressed: _openNew,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni İstem'),
                    )
                  : null,
              filters: [
                ListFiltersRow(
                  fields: [
                    ListFiltersRow.dropdown<RadiologyOrderStatus?>(
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
                        ...RadiologyOrderStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              radiologyOrderStatusLabel(s),
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
              child: FutureBuilder<RadiologyOrderListLoadResult>(
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
                      title: 'Radyoloji istemleri yüklenemedi',
                      description: ClinicalStateMessage.safeErrorDescription(
                        result?.errorMessage ??
                            RadiologyOrderUserMessages.genericLoadFailure,
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

  Widget _buildListBody(List<RadiologyOrder> items) {
    if (items.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.radar_outlined,
        title: 'Radyoloji istemi bulunamadı',
        description: AuthSession.canEditRadiologyOrders
            ? 'X-Ray, MRI, BT veya USG istemi oluşturun.'
            : 'Kayıtlı radyoloji istemi bulunmuyor.',
      );
    }

    return ClinicalSeparatedListBody(
      children: [
        for (final item in items)
          RadiologyOrderListRow(
            order: item,
            onTap: () => _openDetail(item.id),
          ),
      ],
    );
  }
}
