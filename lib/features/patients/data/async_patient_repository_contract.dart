import '../models/patient.dart';

class PatientListPageCursor {
  final String lastName;
  final String firstName;
  final String id;

  const PatientListPageCursor({
    required this.lastName,
    required this.firstName,
    required this.id,
  });

  factory PatientListPageCursor.fromPatient(Patient patient) {
    return PatientListPageCursor(
      lastName: patient.lastName,
      firstName: patient.firstName,
      id: patient.id,
    );
  }
}

class PatientListPage {
  final List<Patient> patients;
  final PatientListPageCursor? nextCursor;

  const PatientListPage({
    required this.patients,
    this.nextCursor,
  });

  bool get hasMore => nextCursor != null;
}

/// Remote hasta erişimi — async sözleşme (UI henüz bu contract'a geçmedi).
///
/// Etiket ilişkileri remote v1 dışında; [PatientRepositoryContract] mock'ta kalır.
/// `tenant_id` UI'dan gelmez — implementasyon [TenantRepositoryScope] kullanır.
abstract interface class AsyncPatientRepositoryContract {
  Future<List<Patient>> getAll();

  Future<List<Patient>> search(String query);

  Future<PatientListPage> listPage({
    String query = '',
    PatientListPageCursor? after,
    int limit = 50,
  });

  Future<Patient?> getById(String id);

  Future<String> getNameById(String id);

  Future<int> count();

  Future<String> nextFileNumber();

  Future<Patient> add(Patient patient);

  Future<Patient> update(Patient patient);

  Future<void> archivePatient(String id);
}
