import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/payment_notification_data_source.dart';
import '../models/payment_staff_notification.dart';

/// Asistan ana ekranı — kalıcı ödeme bildirimleri.
class PaymentNotificationList extends StatefulWidget {
  final List<PaymentStaffNotification> notifications;
  final VoidCallback? onChanged;

  const PaymentNotificationList({
    super.key,
    required this.notifications,
    this.onChanged,
  });

  @override
  State<PaymentNotificationList> createState() => _PaymentNotificationListState();
}

class _PaymentNotificationListState extends State<PaymentNotificationList> {
  Future<void> _markRead(PaymentStaffNotification n) async {
    await PaymentNotificationDataSource.markRead(n.id);
    widget.onChanged?.call();
  }

  Future<void> _markAllRead() async {
    await PaymentNotificationDataSource.markAllRead();
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return Text(
        'Okunmamış ödeme bildirimi yok.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _markAllRead,
            child: const Text('Tümünü okundu işaretle'),
          ),
        ),
        ...widget.notifications.map((n) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: Icon(
                Icons.payments_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${n.body}\n${n.createdByDisplay} · ${_formatDate(n.createdAt)}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Okundu',
                icon: const Icon(Icons.done_all_outlined),
                onPressed: () => _markRead(n),
              ),
              onTap: () async {
                await _markRead(n);
                if (!context.mounted) return;
                context.push('/payments/${n.paymentId}');
              },
            ),
          );
        }),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year}';
  }
}
