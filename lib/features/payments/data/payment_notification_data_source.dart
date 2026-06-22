import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../../clinical_encounter/post_encounter_wizard/models/surgical_quote_currency.dart';
import '../models/payment_record.dart';
import '../models/payment_staff_notification.dart';
import 'payment_notification_refresh.dart';
import 'payment_staff_notification_repository_failure.dart';
import 'payment_staff_notification_repository_provider.dart';

abstract final class PaymentNotificationDataSource {
  static Future<void> notifyAssistantForSurgicalQuote({
    required String patientId,
    required String patientName,
    required String clinicalEncounterId,
    required double? quotedAmount,
    required SurgicalQuoteCurrency currency,
    required String procedureNote,
  }) async {
    final role = AuthSession.currentUser?.role;
    if (role == null || role == AppRoles.assistant) return;

    final performer = AuthSession.currentUser?.displayName ?? 'Hekim';
    final body = quotedAmount != null && quotedAmount > 0
        ? '$patientName hastaya ${quotedAmount.toStringAsFixed(2)} '
            '${currency.notificationLabel} fiyat verildi.'
        : '$patientName — hastaya fiyat verelim.';

    await _tryAddNotification(
      PaymentStaffNotification(
        id: 'quote-notif-${DateTime.now().millisecondsSinceEpoch}',
        paymentId: '',
        patientId: patientId,
        patientName: patientName,
        title: 'Cerrahi teklif bildirimi',
        body: procedureNote.trim().isEmpty ? body : '$body\n${procedureNote.trim()}',
        createdByRole: role,
        createdByDisplay: performer,
        createdAt: DateTime.now(),
      ),
    );
  }

  static Future<void> notifyAssistantForReview(PaymentRecord payment) async {
    if (!TenantFinancialFeatureGate.assistantFinanceNotificationsEnabled) {
      return;
    }
    final role = AuthSession.currentUser?.role;
    if (role == null || role == AppRoles.assistant) return;

    final title = role == AppRoles.doctor
        ? 'Doktor ödeme kaydı'
        : 'Ödeme inceleme bekliyor';

    await _tryAddNotification(
      PaymentStaffNotification(
        id: 'pay-notif-${DateTime.now().millisecondsSinceEpoch}',
        paymentId: payment.id,
        patientId: payment.patientId,
        patientName: payment.patientName,
        title: title,
        body:
            '${payment.patientName} — ${payment.serviceTypeLabel} · '
            '${payment.totalAmount.toStringAsFixed(2)} TL',
        createdByRole: role,
        createdByDisplay: payment.recordedBy,
        createdAt: DateTime.now(),
      ),
    );
  }

  static Future<List<PaymentStaffNotification>> listUnread() async {
    try {
      return await PaymentStaffNotificationRepositoryProvider.repository
          .listUnread();
    } on PaymentStaffNotificationRepositoryException catch (e) {
      if (_isSoftFailure(e.reason)) return const [];
      rethrow;
    }
  }

  static Future<int> unreadCount() async {
    final items = await listUnread();
    return items.length;
  }

  static Future<void> markRead(String notificationId) async {
    final reader = AuthSession.currentUser?.displayName ?? 'Asistan';
    try {
      await PaymentStaffNotificationRepositoryProvider.repository.markRead(
        notificationId,
        readBy: reader,
        at: DateTime.now(),
      );
      PaymentNotificationRefresh.markStale();
    } on PaymentStaffNotificationRepositoryException catch (e) {
      if (_isSoftFailure(e.reason)) return;
      rethrow;
    }
  }

  static Future<void> markAllRead() async {
    final reader = AuthSession.currentUser?.displayName ?? 'Asistan';
    try {
      await PaymentStaffNotificationRepositoryProvider.repository.markAllRead(
        readBy: reader,
        at: DateTime.now(),
      );
      PaymentNotificationRefresh.markStale();
    } on PaymentStaffNotificationRepositoryException catch (e) {
      if (_isSoftFailure(e.reason)) return;
      rethrow;
    }
  }

  static Future<void> _tryAddNotification(
    PaymentStaffNotification notification,
  ) async {
    try {
      await PaymentStaffNotificationRepositoryProvider.repository
          .add(notification);
      PaymentNotificationRefresh.markStale();
    } on PaymentStaffNotificationRepositoryException catch (e) {
      if (_isSoftFailure(e.reason)) return;
      rethrow;
    }
  }

  static bool _isSoftFailure(PaymentStaffNotificationRepositoryFailure reason) {
    return reason == PaymentStaffNotificationRepositoryFailure.notConfigured ||
        reason == PaymentStaffNotificationRepositoryFailure.noActiveTenant ||
        reason == PaymentStaffNotificationRepositoryFailure.network ||
        reason == PaymentStaffNotificationRepositoryFailure.forbidden;
  }
}
