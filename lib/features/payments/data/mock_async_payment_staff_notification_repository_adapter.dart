import '../models/payment_staff_notification.dart';
import 'async_payment_staff_notification_repository_contract.dart';
import 'payment_staff_notification_repository.dart';

class MockAsyncPaymentStaffNotificationRepositoryAdapter
    implements AsyncPaymentStaffNotificationRepositoryContract {
  PaymentStaffNotificationRepository get _sync =>
      PaymentStaffNotificationRepository.instance;

  @override
  Future<void> add(PaymentStaffNotification notification) async {
    _sync.add(notification);
  }

  @override
  Future<List<PaymentStaffNotification>> listUnread() async =>
      _sync.listUnread();

  @override
  Future<void> markAllRead({
    required String readBy,
    required DateTime at,
  }) async {
    _sync.markAllRead(readBy: readBy, at: at);
  }

  @override
  Future<void> markRead(
    String id, {
    required String readBy,
    required DateTime at,
  }) async {
    _sync.markRead(id, readBy: readBy, at: at);
  }
}
