import '../../../core/data/repository_registry.dart';
import '../models/payment_outstanding_patient_alert.dart';
import 'payment_list_user_messages.dart';
import 'payment_repository_failure.dart';

abstract final class PaymentOutstandingAlertsDataSource {
  static Future<List<PaymentOutstandingPatientAlert>> loadAlerts() async {
    try {
      return RepositoryRegistry.paymentsAsync.loadOutstandingAlerts();
    } on PaymentRepositoryException catch (e) {
      throw PaymentListUserMessages.forFailure(e.reason);
    } catch (_) {
      throw PaymentListUserMessages.genericLoadFailure;
    }
  }
}
