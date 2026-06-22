import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../features/inventory/data/inventory_list_refresh.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/dashboard_section.dart';
import '../../core/theme/app_spacing.dart';
import 'data/dashboard_workbench_data_source.dart';
import 'data/dashboard_workbench_load_result.dart';
import 'data/dashboard_workbench_loader.dart';
import 'data/dashboard_workbench_snapshot.dart';
import 'widgets/dashboard_workbench_header.dart';
import 'widgets/dashboard_kpi_strip.dart';
import 'widgets/dashboard_quick_action_list.dart';
import 'widgets/dashboard_workbench_section.dart';

class NurseDashboardScreen extends StatefulWidget {
  const NurseDashboardScreen({super.key});

  @override
  State<NurseDashboardScreen> createState() => _NurseDashboardScreenState();
}

class _NurseDashboardScreenState extends State<NurseDashboardScreen> {
  late Future<DashboardWorkbenchLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = InventoryListRefresh.version;

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
    if (InventoryListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = InventoryListRefresh.version;
    setState(() {
      _loadFuture = DashboardWorkbenchLoader.load(
        DashboardWorkbenchProfile.nurse,
      );
    });
  }

  List<DashboardKpiMetric> _kpiMetrics(DashboardWorkbenchSnapshot snap) {
    if (!AuthSession.canViewInventory) return const [];
    return [
      DashboardKpiMetric(
        label: 'Düşük stok',
        value: DashboardKpiStrip.formatCount(snap.lowStockCount),
      ),
      DashboardKpiMetric(
        label: 'SKT yakın',
        value: DashboardKpiStrip.formatCount(snap.expiringSoonCount),
      ),
      DashboardKpiMetric(
        label: 'SKT geçmiş',
        value: DashboardKpiStrip.formatCount(snap.expiredStockCount),
      ),
    ];
  }

  List<DashboardQuickAction> _quickActions() {
    return DashboardQuickActionList.filterAllowed([
      if (AuthSession.canViewInventory)
        const DashboardQuickAction(
          icon: Icons.inventory_2_outlined,
          label: 'Stok / Sarf',
          route: '/inventory',
        ),
    ], max: 2);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DashboardPageBody(
          child: FutureBuilder<DashboardWorkbenchLoadResult>(
            future: _loadFuture,
            builder: (context, snapshot) {
              final loading = snapshot.connectionState == ConnectionState.waiting;
              final data = snapshot.data;
              final workbench = data?.snapshot;
              final kpis =
                  workbench != null ? _kpiMetrics(workbench) : const <DashboardKpiMetric>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardWorkbenchHeader(
                    title: 'Stok & Sarf',
                    notifications: data?.notifications,
                    onNotificationsChanged: _reload,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (kpis.isNotEmpty)
                              DashboardKpiStrip(
                                isLoading: loading && workbench == null,
                                metrics: kpis,
                              ),
                            if (workbench != null || !loading) ...[
                              if (kpis.isNotEmpty) const SizedBox(height: AppSpacing.lg),
                              DashboardWorkbenchSection(
                                title: 'Hızlı işlemler',
                                child: DashboardQuickActionList(
                                  actions: _quickActions(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
