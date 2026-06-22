import '../models/payment_record.dart';
import 'mock_payment_records.dart';

class PaymentRepository {
  PaymentRepository._();

  static final PaymentRepository instance = PaymentRepository._();

  List<PaymentRecord> getAll() => List.unmodifiable(mockPaymentRecords);

  PaymentRecord? getById(String id) {
    for (final p in mockPaymentRecords) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<PaymentRecord> getByPatientId(String patientId) =>
      mockPaymentRecords.where((p) => p.patientId == patientId).toList();

  List<PaymentRecord> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockPaymentRecords.where((p) => _matchesQuery(p, q)).toList();
  }

  List<PaymentRecord> getFiltered({
    String? patientId,
    String? query,
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
  }) {
    var list = patientId != null && patientId.isNotEmpty
        ? getByPatientId(patientId)
        : getAll();

    if (serviceTypeFilter != null) {
      list = list.where((p) => p.serviceType == serviceTypeFilter).toList();
    }
    if (paymentStatusFilter != null) {
      list = list.where((p) => p.paymentStatus == paymentStatusFilter).toList();
    }
    if (paymentMethodFilter != null) {
      list = list.where((p) => p.paymentMethod == paymentMethodFilter).toList();
    }

    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => _matchesQuery(p, q)).toList();
    }

    return list;
  }

  bool _matchesQuery(PaymentRecord p, String q) {
    if (p.patientName.toLowerCase().contains(q)) return true;
    if (p.serviceTypeLabel.toLowerCase().contains(q)) return true;
    if (p.paymentStatusLabel.toLowerCase().contains(q)) return true;
    if (p.paymentMethodLabel.toLowerCase().contains(q)) return true;
    if (p.notes.toLowerCase().contains(q)) return true;
    return false;
  }

  double getTotalAmount(List<PaymentRecord> records) =>
      records.fold<double>(0, (s, p) => s + p.totalAmount);

  double getTotalPaid(List<PaymentRecord> records) =>
      records.fold<double>(0, (s, p) => s + p.paidAmount);

  double getTotalRemaining(List<PaymentRecord> records) =>
      records.fold<double>(0, (s, p) => s + p.remainingAmount);

  int getPendingCount(List<PaymentRecord> records) =>
      records.where((p) => p.remainingAmount > 0).length;

  void add(PaymentRecord payment) => mockPaymentRecords.insert(0, payment);

  void update(PaymentRecord payment) {
    final index = mockPaymentRecords.indexWhere((p) => p.id == payment.id);
    if (index < 0) return;
    mockPaymentRecords[index] = payment;
  }

  PaymentRecord? getByClinicalEncounterId(String encounterId) {
    final eid = encounterId.trim();
    if (eid.isEmpty) return null;
    for (final p in mockPaymentRecords) {
      if (p.clinicalEncounterId == eid) return p;
    }
    return null;
  }
}
