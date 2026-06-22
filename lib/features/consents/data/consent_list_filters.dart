import '../models/consent_record.dart';

abstract final class ConsentListFilters {
  static List<ConsentRecord> apply({
    required List<ConsentRecord> items,
    ConsentType? consentTypeFilter,
    ConsentStatus? statusFilter,
  }) {
    var list = List<ConsentRecord>.from(items);

    if (consentTypeFilter != null) {
      list = list.where((c) => c.consentType == consentTypeFilter).toList();
    }
    if (statusFilter != null) {
      list = list.where((c) => c.status == statusFilter).toList();
    }

    return list;
  }

  static bool matchesQuery(ConsentRecord c, String q) {
    if (c.patientName.toLowerCase().contains(q)) return true;
    if (c.consentType.toString().split('.').last.toLowerCase().contains(q)) {
      return true;
    }
    if (c.status.toString().split('.').last.toLowerCase().contains(q)) {
      return true;
    }
    if ((c.documentFileName ?? '').toLowerCase().contains(q)) return true;
    if ((c.notes ?? '').toLowerCase().contains(q)) return true;
    return false;
  }
}
