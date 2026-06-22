import '../models/payment_record.dart';
import '../models/payment_outstanding_patient_alert.dart';
import '../models/payment_statistics_snapshot.dart';
import 'async_payment_repository_contract.dart';
import 'payment_list_filters.dart';
import 'payment_list_period_filter.dart';
import 'payment_outstanding_alerts.dart';
import 'payment_repository.dart';
import 'payment_statistics_calculator.dart';

/// Mock sync repository → async contract.
class MockAsyncPaymentRepositoryAdapter
    implements AsyncPaymentRepositoryContract {
  PaymentRepository get _sync => PaymentRepository.instance;

  @override
  Future<List<PaymentRecord>> getAll() async => _sync.getAll();

  @override
  Future<List<PaymentRecord>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<PaymentRecord?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<PaymentRecord>> search(String query) async => _sync.search(query);

  @override
  Future<List<PaymentRecord>> listFiltered({
    String? patientId,
    String query = '',
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
    bool operationalScope = true,
  }) async {
    final q = query.trim().toLowerCase();
    final hasPatient = patientId != null && patientId.trim().isNotEmpty;
    List<PaymentRecord> list;
    if (q.isNotEmpty) {
      list = _sync.search(q);
      if (hasPatient) {
        list = list.where((p) => p.patientId == patientId).toList();
      }
    } else if (hasPatient) {
      list = _sync.getByPatientId(patientId.trim());
    } else {
      list = _sync.getAll();
    }

    if (q.isNotEmpty) {
      list = list.where((p) => PaymentListFilters.matchesQuery(p, q)).toList();
    }
    list = PaymentListFilters.apply(
      items: list,
      serviceTypeFilter: serviceTypeFilter,
      paymentStatusFilter: paymentStatusFilter,
      paymentMethodFilter: paymentMethodFilter,
    );
    if (operationalScope) {
      list = PaymentListPeriodFilter.applyOperationalScope(
        records: list,
        scopedToPatient: false,
      );
    }
    list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return list;
  }

  @override
  Future<PaymentStatisticsSnapshot> loadStatistics({
    required PaymentStatisticsScope scope,
    required int year,
    int? month,
  }) async {
    return PaymentStatisticsCalculator.compute(
      records: _sync.getAll(),
      scope: scope,
      year: year,
      month: month,
    );
  }

  @override
  Future<List<PaymentOutstandingPatientAlert>> loadOutstandingAlerts() async =>
      PaymentOutstandingAlerts.fromRecords(_sync.getAll());

  @override
  Future<PaymentRecord> add(PaymentRecord payment) async {
    _sync.add(payment);
    return payment;
  }

  @override
  Future<PaymentRecord> update(PaymentRecord payment) async {
    _sync.update(payment);
    return payment;
  }

  @override
  Future<PaymentRecord?> getByClinicalEncounterId(String encounterId) async =>
      _sync.getByClinicalEncounterId(encounterId);
}
