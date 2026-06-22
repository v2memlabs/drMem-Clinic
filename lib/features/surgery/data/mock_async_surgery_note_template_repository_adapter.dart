import '../models/surgery_note_template.dart';
import 'async_surgery_note_template_repository_contract.dart';
import 'surgery_note_ownership.dart';
import 'surgery_note_template_repository.dart';

class MockAsyncSurgeryNoteTemplateRepositoryAdapter
    implements AsyncSurgeryNoteTemplateRepositoryContract {
  SurgeryNoteTemplateRepository get _sync => SurgeryNoteTemplateRepository.instance;

  @override
  Future<SurgeryNoteTemplate> create(SurgeryNoteTemplate template) async {
    final profileId = SurgeryNoteOwnership.currentProfileId();
    if (profileId == null || profileId.isEmpty) {
      throw StateError('Profile required to save template');
    }
    final owned = SurgeryNoteTemplate(
      id: template.id,
      profileId: profileId,
      name: template.name,
      description: template.description,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      content: template.content,
    );
    _sync.add(owned);
    return owned;
  }

  @override
  Future<void> delete(String id) async {
    if (!_sync.delete(id)) {
      throw StateError('Template not found: $id');
    }
  }

  @override
  Future<List<SurgeryNoteTemplate>> getAll() async => _sync.getAll();

  @override
  Future<SurgeryNoteTemplate?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<SurgeryNoteTemplate>> search(String query) async =>
      _sync.search(query);

  @override
  Future<SurgeryNoteTemplate> update(SurgeryNoteTemplate template) async {
    final existing = _sync.getById(template.id);
    if (existing == null) {
      throw StateError('Template not found: ${template.id}');
    }
    _sync.update(template);
    return template;
  }
}
