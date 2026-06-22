import '../models/prescription.dart';
import 'mock_prescriptions.dart';

class PrescriptionRepository {
  PrescriptionRepository._();

  static final PrescriptionRepository instance = PrescriptionRepository._();

  List<Prescription> getAll() => List.unmodifiable(mockPrescriptions);

  Prescription? getById(String id) {
    for (final item in mockPrescriptions) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<Prescription> getByPatientId(String patientId) =>
      mockPrescriptions.where((p) => p.patientId == patientId).toList();

  List<Prescription> getFiltered({
    String? patientId,
    String? query,
    PrescriptionStatus? statusFilter,
  }) {
    var list = patientId != null && patientId.isNotEmpty
        ? getByPatientId(patientId)
        : getAll();

    if (statusFilter != null) {
      list = list.where((p) => p.status == statusFilter).toList();
    }

    final q = (query ?? '').trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => _matchesQuery(p, q)).toList();
    }

    return list;
  }

  bool _matchesQuery(Prescription p, String q) {
    return matchesQuery(p, q);
  }

  static bool matchesQuery(Prescription p, String q) {
    if (p.patientName.toLowerCase().contains(q)) return true;
    if (p.diagnosis.toLowerCase().contains(q)) return true;
    if (p.createdBy.toLowerCase().contains(q)) return true;
    for (final med in p.medications) {
      if (med.name.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  void add(Prescription prescription) => mockPrescriptions.insert(0, prescription);

  void update(Prescription prescription) {
    final index = mockPrescriptions.indexWhere((p) => p.id == prescription.id);
    if (index >= 0) {
      mockPrescriptions[index] = prescription;
    }
  }
}
