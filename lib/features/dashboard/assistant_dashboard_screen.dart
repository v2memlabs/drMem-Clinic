import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
import '../../features/consents/data/consent_list_refresh.dart';
import '../../features/payments/data/payment_notification_refresh.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/dashboard_section.dart';
import '../../core/theme/app_spacing.dart';
import 'data/dashboard_workbench_data_source.dart';
import 'data/dashboard_workbench_load_result.dart';
import 'data/dashboard_workbench_loader.dart';
import 'data/dashboard_workbench_snapshot.dart';
import 'widgets/dashboard_kpi_strip.dart';
import 'widgets/dashboard_quick_action_list.dart';
import 'widgets/dashboard_today_schedule_list.dart';
import 'widgets/dashboard_workbench_header.dart';
import 'widgets/dashboard_workbench_section.dart';

class AssistantDashboardScreen extends StatefulWidget {
  const AssistantDashboardScreen({super.key});

  @override
  State<AssistantDashboardScreen> createState() => _AssistantDashboardScreenState();
}

class _AssistantDashboardScreenState extends State<AssistantDashboardScreen> {
  late Future<DashboardWorkbenchLoadResult> _loadFuture;
  bool _activatedOnce = false;
  int _lastRefreshVersion = ConsentListRefresh.version;
  int _lastPaymentNotificationVersion = PaymentNotificationRefresh.version;

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
    if (ConsentListRefresh.isStale(_lastRefreshVersion) ||
        PaymentNotificationRefresh.isStale(_lastPaymentNotificationVersion)) {
      _reload();
    }
  }

  void _reload() {
    _lastRefreshVersion = ConsentListRefresh.version;
    _lastPaymentNotificationVersion = PaymentNotificationRefresh.version;
    setState(() {
      _loadFuture = DashboardWorkbenchLoader.load(
        DashboardWorkbenchProfile.assistant,
      );
    });
  }

  List<DashboardKpiMetric> _kpiMetrics(DashboardWorkbenchSnapshot snap) {
    final metrics = <DashboardKpiMetric>[
      DashboardKpiMetric(
        label: 'Bugün randevu',
        value: DashboardKpiStrip.formatCount(
          snap.todayAppointmentCount,
          unavailable: snap.appointmentsUnavailable,
        ),
      ),
      DashboardKpiMetric(
        label: 'Bekleyen',
        value: DashboardKpiStrip.formatCount(
          snap.pendingAppointmentCount,
          unavailable: snap.appointmentsUnavailable,
        ),
      ),
    ];
    if (AuthSession.canViewConsents && snap.pendingConsentCount != null) {
      metrics.add(
        DashboardKpiMetric(
          label: 'Onam bekleyen',
          value: snap.pendingConsentCount.toString(),
        ),
      );
    }
    return metrics;
  }

  List<DashboardQuickAction> _quickActions() {
    return DashboardQuickActionList.filterAllowed([
      if (AuthSession.canViewAppointments)
        const DashboardQuickAction(
          icon: Icons.event_available_outlined,
          label: 'Yeni Randevu',
          route: '/appointments/new',
        ),
      if (AuthSession.canViewConsents)
        const DashboardQuickAction(
          icon: Icons.privacy_tip_outlined,
          label: 'KVKK / Onam',
          route: '/consents',
        ),
      if (AuthSession.canViewPayments)
        const DashboardQuickAction(
          icon: Icons.payments_outlined,
          label: 'Ödeme',
          route: '/payments',
        ),
      if (AuthSession.canViewFiles)
        const DashboardQuickAction(
          icon: Icons.upload_file_outlined,
          label: 'Dosya Yükle',
          route: '/files/upload',
        ),
    ], max: 4);
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
              final notifications = data?.notifications;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardWorkbenchHeader(
                    title: 'Operasyon',
                    notifications: notifications,
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
                            DashboardKpiStrip(
                              isLoading: loading && workbench == null,
                              metrics:
                                  workbench != null ? _kpiMetrics(workbench) : const [],
                            ),
                            if (workbench != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              if (AuthSession.canViewAppointments)
                                DashboardWorkbenchSection(
                                  title: 'Bugünkü randevular',
                                  child: DashboardTodayScheduleList(
                                    appointments: workbench.schedulePreview,
                                    appointmentsUnavailable:
                                        workbench.appointmentsUnavailable,
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.lg),
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
