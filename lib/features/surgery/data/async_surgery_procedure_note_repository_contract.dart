import '../models/surgery_procedure_note.dart';

abstract interface class AsyncSurgeryProcedureNoteRepositoryContract {
  Future<List<SurgeryProcedureNote>> getAll();

  Future<List<SurgeryProcedureNote>> getByPatientId(String patientId);

  Future<SurgeryProcedureNote?> getById(String id);

  Future<List<SurgeryProcedureNote>> search(String query);

  Future<SurgeryProcedureNote> create(SurgeryProcedureNote note);

  Future<SurgeryProcedureNote> update(SurgeryProcedureNote note);

  Future<SurgeryProcedureNote> updateNotes(String id, String notes);
}
