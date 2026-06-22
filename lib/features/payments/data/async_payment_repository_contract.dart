import '../models/payment_record.dart';
import '../models/payment_outstanding_patient_alert.dart';
import '../models/payment_statistics_snapshot.dart';

/// Async ödeme repository — liste/detay/form active backend hattı.
abstract interface class AsyncPaymentRepositoryContract {
  Future<List<PaymentRecord>> getAll();

  Future<List<PaymentRecord>> getByPatientId(String patientId);

  Future<PaymentRecord?> getById(String id);

  Future<List<PaymentRecord>> search(String query);

  Future<List<PaymentRecord>> listFiltered({
    String? patientId,
    String query = '',
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
    bool operationalScope = true,
  });

  Future<PaymentStatisticsSnapshot> loadStatistics({
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  });

  Future<List<PaymentOutstandingPatientAlert>> loadOutstandingAlerts();

  Future<PaymentRecord> add(PaymentRecord payment);

  Future<PaymentRecord> update(PaymentRecord payment);

  Future<PaymentRecord?> getByClinicalEncounterId(String encounterId);
}
