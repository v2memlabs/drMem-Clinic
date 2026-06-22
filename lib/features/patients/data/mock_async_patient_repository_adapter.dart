import '../models/patient.dart';
import 'async_patient_repository_contract.dart';
import 'patient_repository.dart';
import 'patient_repository_contract.dart';

/// Mock sync repository → async contract (anında tamamlanan Future).
///
/// Aktif UI bağlı değil; ileride provider switch için hazır.
class MockAsyncPatientRepositoryAdapter
    implements AsyncPatientRepositoryContract {
  PatientRepositoryContract get _sync => PatientRepository.instance;

  @override
  Future<List<Patient>> getAll() async => _sync.getAll();

  @override
  Future<List<Patient>> search(String query) async => _sync.search(query);

  @override
  Future<PatientListPage> listPage({
    String query = '',
    PatientListPageCursor? after,
    int limit = 50,
  }) async {
    final source = query.trim().isEmpty ? _sync.getAll() : _sync.search(query);
    final sorted = List<Patient>.from(source)
      ..sort((a, b) {
        final last =
            a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
        if (last != 0) return last;
        final first =
            a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase());
        if (first != 0) return first;
        return a.id.compareTo(b.id);
      });

    var start = 0;
    if (after != null) {
      final index = sorted.indexWhere((p) => p.id == after.id);
      start = index < 0 ? 0 : index + 1;
    }

    final safeLimit = limit.clamp(1, 100).toInt();
    final window = sorted.skip(start).take(safeLimit + 1).toList();
    final hasMore = window.length > safeLimit;
    final patients = hasMore ? window.take(safeLimit).toList() : window;
    return PatientListPage(
      patients: patients,
      nextCursor: hasMore && patients.isNotEmpty
          ? PatientListPageCursor.fromPatient(patients.last)
          : null,
    );
  }

  @override
  Future<Patient?> getById(String id) async => _sync.getById(id);

  @override
  Future<String> getNameById(String id) async => _sync.getNameById(id);

  @override
  Future<int> count() async => _sync.count();

  @override
  Future<String> nextFileNumber() async => _sync.nextFileNumber();

  @override
  Future<Patient> add(Patient patient) async {
    _sync.add(patient);
    return patient;
  }

  @override
  Future<Patient> update(Patient patient) async {
    final ok = _sync.update(patient);
    if (!ok) {
      throw StateError('Mock patient update failed: ${patient.id}');
    }
    return patient;
  }

  @override
  Future<void> archivePatient(String id) async {
    // Mock'ta soft delete yok — remote v1 hazırlığı; no-op.
  }
}
