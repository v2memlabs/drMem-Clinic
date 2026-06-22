import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session.dart';
import '../../core/theme/app_radius.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/dashboard_section.dart';
import '../../core/theme/app_spacing.dart';
import 'data/dashboard_workbench_data_source.dart';
import 'data/dashboard_workbench_load_result.dart';
import 'data/dashboard_workbench_loader.dart';
import 'widgets/dashboard_workbench_header.dart';
import '../physiotherapy/data/physiotherapy_referral_list_refresh.dart';
import 'data/dashboard_workbench_snapshot.dart';
import 'widgets/dashboard_kpi_strip.dart';
import 'widgets/dashboard_quick_action_list.dart';
import 'widgets/dashboard_workbench_section.dart';

class PhysiotherapistDashboardScreen extends StatefulWidget {
  const PhysiotherapistDashboardScreen({super.key});

  @override
  State<PhysiotherapistDashboardScreen> createState() =>
      _PhysiotherapistDashboardScreenState();
}

class _PhysiotherapistDashboardScreenState
    extends State<PhysiotherapistDashboardScreen> {
  late Future<DashboardWorkbenchLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = PhysiotherapyReferralListRefresh.version;

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
    if (PhysiotherapyReferralListRefresh.isStale(_lastRefreshVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = PhysiotherapyReferralListRefresh.version;
    setState(() {
      _loadFuture = DashboardWorkbenchLoader.load(
        DashboardWorkbenchProfile.physiotherapist,
      );
    });
  }

  List<DashboardKpiMetric> _kpiMetrics(DashboardWorkbenchSnapshot snap) {
    return [
      DashboardKpiMetric(
        label: 'Bekleyen hastalar',
        value: DashboardKpiStrip.formatCount(
          snap.newPhysiotherapyReferralCount,
          unavailable: snap.physiotherapyReferralsUnavailable,
        ),
      ),
    ];
  }

  List<DashboardQuickAction> _quickActions() {
    return DashboardQuickActionList.filterAllowed([
      const DashboardQuickAction(
        icon: Icons.pending_actions_outlined,
        label: 'Bekleyen Yönlendirmeler',
        route: '/physiotherapy/referrals/pending',
      ),
      const DashboardQuickAction(
        icon: Icons.event_outlined,
        label: 'Randevularım',
        route: '/appointments',
      ),
      if (AuthSession.canViewPhysiotherapy)
        const DashboardQuickAction(
          icon: Icons.note_alt_outlined,
          label: 'Seans Notları',
          route: '/physiotherapy/sessions',
        ),
    ], max: 3);
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardWorkbenchHeader(
                    title: 'Fizyoterapi',
                    notifications: data?.notifications,
                    onNotificationsChanged: _reload,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  context.go('/physiotherapy/referrals'),
                              borderRadius: AppRadius.mediumBorder,
                              child: DashboardKpiStrip(
                                isLoading: loading && workbench == null,
                                metrics: workbench != null
                                    ? _kpiMetrics(workbench)
                                    : const [],
                              ),
                            ),
                          ),
                          if (workbench != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            DashboardWorkbenchSection(
                              title: 'FTR iş akışı',
                              child: DashboardQuickActionList(
                                actions: _quickActions(),
                              ),
                            ),
                          ],
                        ],
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
