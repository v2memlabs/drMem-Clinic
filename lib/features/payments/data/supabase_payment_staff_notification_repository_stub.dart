import '../models/payment_staff_notification.dart';
import 'async_payment_staff_notification_repository_contract.dart';
import 'payment_staff_notification_repository_failure.dart';

/// Supabase oturum/rol hazır değilken — mock adapter'a düşülmez.
class SupabasePaymentStaffNotificationRepositoryStub
    implements AsyncPaymentStaffNotificationRepositoryContract {
  const SupabasePaymentStaffNotificationRepositoryStub();

  static Never _notReady() {
    throw const PaymentStaffNotificationRepositoryException(
      PaymentStaffNotificationRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<PaymentStaffNotification>> listUnread() async => _notReady();

  @override
  Future<void> add(PaymentStaffNotification notification) async => _notReady();

  @override
  Future<void> markRead(
    String id, {
    required String readBy,
    required DateTime at,
  }) async =>
      _notReady();

  @override
  Future<void> markAllRead({
    required String readBy,
    required DateTime at,
  }) async =>
      _notReady();
}
