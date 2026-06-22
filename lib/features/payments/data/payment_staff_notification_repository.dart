import '../models/payment_staff_notification.dart';
import 'mock_payment_staff_notifications.dart';

class PaymentStaffNotificationRepository {
  PaymentStaffNotificationRepository._();

  static final PaymentStaffNotificationRepository instance =
      PaymentStaffNotificationRepository._();

  List<PaymentStaffNotification> listUnread() {
    return mockPaymentStaffNotifications
        .where((n) => !n.isRead)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PaymentStaffNotification> listAll() {
    return List<PaymentStaffNotification>.from(mockPaymentStaffNotifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int unreadCount() => listUnread().length;

  void add(PaymentStaffNotification notification) {
    mockPaymentStaffNotifications.insert(0, notification);
  }

  PaymentStaffNotification? getById(String id) {
    for (final n in mockPaymentStaffNotifications) {
      if (n.id == id) return n;
    }
    return null;
  }

  void markRead(String id, {required String readBy, required DateTime at}) {
    final index =
        mockPaymentStaffNotifications.indexWhere((n) => n.id == id);
    if (index < 0) return;
    mockPaymentStaffNotifications[index] =
        mockPaymentStaffNotifications[index].markRead(at: at, readBy: readBy);
  }

  void markAllRead({required String readBy, required DateTime at}) {
    for (var i = 0; i < mockPaymentStaffNotifications.length; i++) {
      if (!mockPaymentStaffNotifications[i].isRead) {
        mockPaymentStaffNotifications[i] =
            mockPaymentStaffNotifications[i].markRead(at: at, readBy: readBy);
      }
    }
  }
}
