import '../models/payment_record.dart';

/// Ödeme listesi client-side filtre.
abstract final class PaymentListFilters {
  static List<PaymentRecord> apply({
    required List<PaymentRecord> items,
    ServiceType? serviceTypeFilter,
    PaymentStatus? paymentStatusFilter,
    PaymentMethod? paymentMethodFilter,
  }) {
    var list = List<PaymentRecord>.from(items);

    if (serviceTypeFilter != null) {
      list = list.where((p) => p.serviceType == serviceTypeFilter).toList();
    }
    if (paymentStatusFilter != null) {
      list =
          list.where((p) => p.paymentStatus == paymentStatusFilter).toList();
    }
    if (paymentMethodFilter != null) {
      list =
          list.where((p) => p.paymentMethod == paymentMethodFilter).toList();
    }

    return list;
  }

  static bool matchesQuery(PaymentRecord p, String q) {
    if (p.patientName.toLowerCase().contains(q)) return true;
    if (p.serviceTypeLabel.toLowerCase().contains(q)) return true;
    if (p.paymentStatusLabel.toLowerCase().contains(q)) return true;
    if (p.paymentMethodLabel.toLowerCase().contains(q)) return true;
    if (p.notes.toLowerCase().contains(q)) return true;
    return false;
  }
}
