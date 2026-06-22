import '../models/payment_record.dart';
import '../models/payment_outstanding_patient_alert.dart';
import '../models/payment_statistics_snapshot.dart';
import 'async_payment_repository_contract.dart';
import 'payment_repository_failure.dart';

/// Supabase `payments` tablosu hazır olana kadar — güvenli notConfigured.
class SupabasePaymentRepositoryStub implements AsyncPaymentRepositoryContract {
  const SupabasePaymentRepositoryStub();

  static Never _notReady() {
    throw const PaymentRepositoryException(
      PaymentRepositoryFailure.notConfigured,
    );
  }

  @override
  Future<List<PaymentRecord>> getAll() async => _notReady();

  @override
  Future<List<PaymentRecord>> getByPatientId(String patientId) async =>
      _notReady();

  @override
  Future<PaymentRecord?> getById(String id) async => _notReady();

  @override
  Future<List<PaymentRecord>> search(String query) async => _notReady();

  @override
  Future<List<PaymentRecord>> listFiltered({
    String? patientId,
    String query = '',
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
    bool operationalScope = true,
  }) async =>
      _notReady();

  @override
  Future<PaymentStatisticsSnapshot> loadStatistics({
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  }) async =>
      _notReady();

  @override
  Future<List<PaymentOutstandingPatientAlert>> loadOutstandingAlerts() async =>
      _notReady();

  @override
  Future<PaymentRecord> add(PaymentRecord payment) async => _notReady();

  @override
  Future<PaymentRecord> update(PaymentRecord payment) async => _notReady();

  @override
  Future<PaymentRecord?> getByClinicalEncounterId(String encounterId) async =>
      _notReady();
}
