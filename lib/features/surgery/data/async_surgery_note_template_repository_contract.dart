import '../models/surgery_note_template.dart';

abstract interface class AsyncSurgeryNoteTemplateRepositoryContract {
  Future<List<SurgeryNoteTemplate>> getAll();

  Future<SurgeryNoteTemplate?> getById(String id);

  Future<List<SurgeryNoteTemplate>> search(String query);

  Future<SurgeryNoteTemplate> create(SurgeryNoteTemplate template);

  Future<SurgeryNoteTemplate> update(SurgeryNoteTemplate template);

  Future<void> delete(String id);
}
