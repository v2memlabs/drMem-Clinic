/// Asistan / fizyoterapist güvenli muayene özeti — ayrı paket (stub).
///
/// Full [ClinicalEncounter] veya `internal_doctor_note` döndürmez.
abstract interface class AsyncClinicalEncounterOperationalSummaryContract {
  Future<List<Map<String, dynamic>>> listSummaries({String? patientId});

  Future<Map<String, dynamic>?> getSummaryById(String id);
}
