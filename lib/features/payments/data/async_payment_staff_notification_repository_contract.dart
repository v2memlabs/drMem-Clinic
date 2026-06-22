import '../models/payment_staff_notification.dart';

abstract interface class AsyncPaymentStaffNotificationRepositoryContract {
  Future<List<PaymentStaffNotification>> listUnread();

  Future<void> add(PaymentStaffNotification notification);

  Future<void> markRead(
    String id, {
    required String readBy,
    required DateTime at,
  });

  Future<void> markAllRead({
    required String readBy,
    required DateTime at,
  });
}
