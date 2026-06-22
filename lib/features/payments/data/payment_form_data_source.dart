import '../../../core/auth/auth_session.dart';
import '../../../core/data/repository_registry.dart';
import '../models/payment_record.dart';
import 'payment_list_user_messages.dart';
import 'payment_notification_data_source.dart';
import 'payment_permissions.dart';
import 'payment_repository_failure.dart';

class PaymentFormSaveResult {
  final PaymentRecord? record;
  final String? errorMessage;

  const PaymentFormSaveResult._({this.record, this.errorMessage});

  factory PaymentFormSaveResult.success(PaymentRecord record) {
    return PaymentFormSaveResult._(record: record);
  }

  factory PaymentFormSaveResult.failure(String message) {
    return PaymentFormSaveResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class PaymentFormDataSource {
  static Future<PaymentRecord?> loadForEdit(String id) async {
    try {
      return await RepositoryRegistry.paymentsAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<PaymentFormSaveResult> add(PaymentRecord record) async {
    try {
      final withMeta = _attachCreatorMeta(record);
      final saved = await RepositoryRegistry.paymentsAsync.add(withMeta);
      try {
        await PaymentNotificationDataSource.notifyAssistantForReview(saved);
      } catch (_) {
        // Bildirim başarısız olsa da ödeme kaydı korunur.
      }
      return PaymentFormSaveResult.success(saved);
    } on PaymentRepositoryException catch (e) {
      return PaymentFormSaveResult.failure(
        PaymentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PaymentFormSaveResult.failure(
        PaymentListUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<PaymentFormSaveResult> update(PaymentRecord record) async {
    if (!PaymentPermissions.canEditPayment(record)) {
      return PaymentFormSaveResult.failure(
        'Bu ödeme kaydını düzenleme yetkiniz yok.',
      );
    }

    try {
      final saved = await RepositoryRegistry.paymentsAsync.update(record);
      return PaymentFormSaveResult.success(saved);
    } on PaymentRepositoryException catch (e) {
      return PaymentFormSaveResult.failure(
        PaymentListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PaymentFormSaveResult.failure(
        PaymentListUserMessages.genericLoadFailure,
      );
    }
  }

  static PaymentRecord _attachCreatorMeta(PaymentRecord record) {
    final user = AuthSession.currentUser;
    if (user == null) return record;
    return record.copyWith(
      recordedBy: record.recordedBy.trim().isEmpty
          ? user.displayName
          : record.recordedBy,
      createdByUserId: user.id,
    );
  }
}
