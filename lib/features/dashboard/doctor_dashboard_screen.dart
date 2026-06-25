import 'package:flutter/material.dart';

import '../../core/auth/auth_session.dart';
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
import 'widgets/dashboard_today_schedule_list.dart';
import 'widgets/dashboard_workbench_section.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  late Future<DashboardWorkbenchLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture = DashboardWorkbenchLoader.load(
        DashboardWorkbenchProfile.doctor,
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
      DashboardKpiMetric(
        label: 'Bugün muayene',
        value: DashboardKpiStrip.formatCount(
          snap.todayClinicalEncounterCount,
          unavailable: snap.clinicalEncountersUnavailable,
        ),
      ),
    ];
    if (AuthSession.canViewPdfOutputs) {
      metrics.add(
        DashboardKpiMetric(
          label: 'Bugün PDF',
          value: DashboardKpiStrip.formatCount(
            snap.todayPdfOutputCount,
            unavailable: snap.pdfOutputsUnavailable,
          ),
        ),
      );
    }
    return metrics;
  }

  List<DashboardQuickAction> _quickActions() {
    return DashboardQuickActionList.filterAllowed([
      if (AuthSession.canEditClinicalEncounters)
        const DashboardQuickAction(
          icon: Icons.add_circle_outline,
          label: 'Yeni Muayene',
          route: '/clinical-records/new',
        ),
      if (AuthSession.canEditAppointments)
        const DashboardQuickAction(
          icon: Icons.event_available_outlined,
          label: 'Yeni Randevu',
          route: '/appointments/new',
        ),
      if (AuthSession.canViewPdfOutputs)
        const DashboardQuickAction(
          icon: Icons.picture_as_pdf_outlined,
          label: 'PDF Çıktı',
          route: '/pdf-outputs',
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

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardWorkbenchHeader(
                    title: 'Bugün',
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
                            DashboardKpiStrip(
                              isLoading: loading && workbench == null,
                              metrics: workbench != null
                                  ? _kpiMetrics(workbench)
                                  : const [],
                            ),
                            if (workbench != null) ...[
                              const SizedBox(height: AppSpacing.lg),
                              if (AuthSession.canViewAppointments)
                                DashboardWorkbenchSection(
                                  title: 'Bugünkü akış',
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
