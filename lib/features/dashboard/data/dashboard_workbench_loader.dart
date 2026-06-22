import '../notifications/dashboard_notification_aggregator.dart';
import 'dashboard_workbench_data_source.dart';
import 'dashboard_workbench_load_result.dart';

abstract final class DashboardWorkbenchLoader {
  static Future<DashboardWorkbenchLoadResult> load(
    DashboardWorkbenchProfile profile,
  ) async {
    final snapshot = await DashboardWorkbenchDataSource.load(profile);
    final notifications = await DashboardNotificationAggregator.load(snapshot);
    return DashboardWorkbenchLoadResult(
      snapshot: snapshot,
      notifications: notifications,
    );
  }
}
