import 'package:flutter/material.dart';

import '../../../shared/widgets/page_header.dart';
import '../notifications/dashboard_notification_models.dart';
import 'dashboard_notifications_sheet.dart';

/// Dashboard ana ekran başlığı — tarih/saat + uyarı butonu.
class DashboardWorkbenchHeader extends StatelessWidget {
  final String title;
  final DashboardNotificationSummary? notifications;
  final VoidCallback? onNotificationsChanged;

  const DashboardWorkbenchHeader({
    super.key,
    required this.title,
    this.notifications,
    this.onNotificationsChanged,
  });

  Future<void> _openNotifications(BuildContext context) async {
    final summary = notifications;
    if (summary == null || !summary.hasAlerts) return;
    await showDashboardNotificationsSheet(
      context: context,
      summary: summary,
      onChanged: onNotificationsChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = notifications?.totalCount ?? 0;
    return PageHeader(
      title: title,
      alertCount: count,
      onAlertTap: count > 0 ? () => _openNotifications(context) : null,
    );
  }
}
