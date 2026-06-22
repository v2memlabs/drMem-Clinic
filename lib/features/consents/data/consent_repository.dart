import '../models/consent_record.dart';
import 'mock_consent_records.dart';

class ConsentRepository {
  ConsentRepository._();

  static final ConsentRepository instance = ConsentRepository._();

  List<ConsentRecord> getAll() => List.unmodifiable(mockConsentRecords);

  ConsentRecord? getById(String id) {
    for (final c in mockConsentRecords) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<ConsentRecord> getByPatientId(String patientId) =>
      mockConsentRecords.where((c) => c.patientId == patientId).toList();

  List<ConsentRecord> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockConsentRecords.where((c) => _matchesQuery(c, q)).toList();
  }

  List<ConsentRecord> getFiltered({
    String? patientId,
    String? query,
    ConsentType? consentTypeFilter,
    ConsentStatus? statusFilter,
  }) {
    var list = patientId != null && patientId.isNotEmpty
        ? getByPatientId(patientId)
        : getAll();

    if (consentTypeFilter != null) {
      list = list.where((c) => c.consentType == consentTypeFilter).toList();
    }
    if (statusFilter != null) {
      list = list.where((c) => c.status == statusFilter).toList();
    }

    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) => _matchesQuery(c, q)).toList();
    }

    return list;
  }

  bool _matchesQuery(ConsentRecord c, String q) {
    if (c.patientName.toLowerCase().contains(q)) return true;
    if (c.consentType.toString().split('.').last.toLowerCase().contains(q)) {
      return true;
    }
    if (c.status.toString().split('.').last.toLowerCase().contains(q)) return true;
    if ((c.documentFileName ?? '').toLowerCase().contains(q)) return true;
    if ((c.notes ?? '').toLowerCase().contains(q)) return true;
    return false;
  }

  void add(ConsentRecord consent) => mockConsentRecords.insert(0, consent);

  void update(ConsentRecord consent) {
    final index = mockConsentRecords.indexWhere((c) => c.id == consent.id);
    if (index >= 0) {
      mockConsentRecords[index] = consent;
    }
  }
}
