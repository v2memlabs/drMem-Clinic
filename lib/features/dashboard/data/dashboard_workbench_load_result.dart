import '../notifications/dashboard_notification_models.dart';
import 'dashboard_workbench_snapshot.dart';

class DashboardWorkbenchLoadResult {
  final DashboardWorkbenchSnapshot snapshot;
  final DashboardNotificationSummary notifications;

  const DashboardWorkbenchLoadResult({
    required this.snapshot,
    required this.notifications,
  });
}
