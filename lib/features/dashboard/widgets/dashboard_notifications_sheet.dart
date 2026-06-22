import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/holiday_calendar_sheet.dart';
import '../../payments/data/payment_notification_data_source.dart';
import '../notifications/dashboard_notification_dismissals.dart';
import '../notifications/dashboard_notification_models.dart';

Future<void> showDashboardNotificationsSheet({
  required BuildContext context,
  required DashboardNotificationSummary summary,
  VoidCallback? onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _DashboardNotificationsSheet(
      summary: summary,
      onChanged: onChanged,
    ),
  );
}

class _DashboardNotificationsSheet extends StatefulWidget {
  final DashboardNotificationSummary summary;
  final VoidCallback? onChanged;

  const _DashboardNotificationsSheet({
    required this.summary,
    this.onChanged,
  });

  @override
  State<_DashboardNotificationsSheet> createState() =>
      _DashboardNotificationsSheetState();
}

class _DashboardNotificationsSheetState
    extends State<_DashboardNotificationsSheet> {
  late DashboardNotificationSummary _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.summary;
  }

  void _applyDismiss(String entryId) {
    DashboardNotificationDismissals.dismiss(entryId);
    setState(() {
      _summary = _summary.withoutEntry(entryId);
    });
    widget.onChanged?.call();
  }

  Future<void> _markAllRead() async {
    final paymentEntryIds = _summary.entryIds
        .where(
          (id) => id.startsWith('payment:') || id.startsWith('outstanding:'),
        )
        .toList();
    if (paymentEntryIds.any((id) => id.startsWith('payment:'))) {
      await PaymentNotificationDataSource.markAllRead();
    }
    DashboardNotificationDismissals.dismissAll(paymentEntryIds);
    if (!mounted) return;
    setState(() {
      _summary = _summary.withoutEntries(paymentEntryIds);
    });
    widget.onChanged?.call();
  }

  Future<void> _openEntry(
    BuildContext context,
    DashboardNotificationEntry entry,
  ) async {
    _applyDismiss(entry.id);

    final payment = entry.paymentNotification;
    if (payment != null) {
      await PaymentNotificationDataSource.markRead(payment.id);
      if (!context.mounted) return;
      final route = entry.route;
      if (route != null && route.isNotEmpty) {
        Navigator.pop(context);
        context.push(route);
      }
      return;
    }

    if (entry.opensCalendar) {
      Navigator.pop(context);
      await showHolidayCalendarSheet(context);
      return;
    }

    final route = entry.route;
    if (route == null || route.isEmpty) return;
    Navigator.pop(context);
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasPaymentEntries = _summary.categories.any(
      (category) =>
          category.id == 'payment' || category.id == 'payment_staff',
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bildirimler',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (hasPaymentEntries)
                  TextButton(
                    onPressed: _summary.hasAlerts ? _markAllRead : null,
                    child: Text('Kapat'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _summary.hasAlerts
                  ? '${_summary.totalCount} okunmamış uyarı'
                  : 'Okunmamış uyarı yok',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_summary.hasAlerts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Tüm bildirimler okundu.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final category in _summary.categories) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          category.title,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDeepTeal,
                                  ),
                        ),
                      ),
                      for (final entry in category.entries)
                        Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            leading: Icon(category.icon),
                            title: Text(entry.title),
                            subtitle: entry.subtitle != null
                                ? Text(entry.subtitle!)
                                : null,
                            trailing: entry.count > 1
                                ? CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.danger
                                        .withValues(alpha: 0.12),
                                    child: Text(
                                      entry.count.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: () => _openEntry(context, entry),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
