import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../models/payment_record.dart';

/// Ödeme kaydı düzenleme — rol ve kayıt sahipliği.
abstract final class PaymentPermissions {
  static bool canCreatePayment() => AuthSession.canCreatePayments;

  static bool canEditPayment(PaymentRecord record) {
    if (!AuthSession.canEditPayments) return false;
    if (AuthSession.currentUser?.role == AppRoles.physiotherapist) {
      final uid = AuthSession.currentUser?.id;
      if (uid == null || uid.isEmpty) return false;
      return record.createdByUserId == uid;
    }
    return true;
  }

  static bool canEditPaymentAmounts(PaymentRecord record) =>
      canEditPayment(record);

  static bool canChargePatientMaterials() =>
      AuthSession.canChargePatientMaterials;
}
