import '../models/surgery_note_template.dart';
import 'async_surgery_note_template_repository_contract.dart';
import 'surgery_procedure_note_repository_failure.dart';

class SupabaseAsyncSurgeryNoteTemplateRepositoryStub
    implements AsyncSurgeryNoteTemplateRepositoryContract {
  const SupabaseAsyncSurgeryNoteTemplateRepositoryStub();

  static const _error = SurgeryProcedureNoteRepositoryException(
    SurgeryProcedureNoteRepositoryFailure.notConfigured,
  );

  @override
  Future<SurgeryNoteTemplate> create(SurgeryNoteTemplate template) async =>
      throw _error;

  @override
  Future<void> delete(String id) async => throw _error;

  @override
  Future<List<SurgeryNoteTemplate>> getAll() async => throw _error;

  @override
  Future<SurgeryNoteTemplate?> getById(String id) async => throw _error;

  @override
  Future<List<SurgeryNoteTemplate>> search(String query) async => throw _error;

  @override
  Future<SurgeryNoteTemplate> update(SurgeryNoteTemplate template) async =>
      throw _error;
}
