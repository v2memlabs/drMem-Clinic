import '../models/surgery_procedure_note.dart';
import 'async_surgery_procedure_note_repository_contract.dart';
import 'surgery_procedure_note_repository_failure.dart';

class SupabaseAsyncSurgeryProcedureNoteRepositoryStub
    implements AsyncSurgeryProcedureNoteRepositoryContract {
  const SupabaseAsyncSurgeryProcedureNoteRepositoryStub();

  static const _error = SurgeryProcedureNoteRepositoryException(
    SurgeryProcedureNoteRepositoryFailure.notConfigured,
  );

  @override
  Future<SurgeryProcedureNote> create(SurgeryProcedureNote note) async {
    throw _error;
  }

  @override
  Future<List<SurgeryProcedureNote>> getAll() async => throw _error;

  @override
  Future<SurgeryProcedureNote?> getById(String id) async => throw _error;

  @override
  Future<List<SurgeryProcedureNote>> getByPatientId(String patientId) async =>
      throw _error;

  @override
  Future<List<SurgeryProcedureNote>> search(String query) async => throw _error;

  @override
  Future<SurgeryProcedureNote> update(SurgeryProcedureNote note) async =>
      throw _error;

  @override
  Future<SurgeryProcedureNote> updateNotes(String id, String notes) async =>
      throw _error;
}
