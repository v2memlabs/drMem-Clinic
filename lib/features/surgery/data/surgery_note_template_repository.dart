import '../models/surgery_note_template.dart';
import 'mock_surgery_note_templates.dart';
import 'surgery_note_ownership.dart';

class SurgeryNoteTemplateRepository {
  SurgeryNoteTemplateRepository._();

  static final SurgeryNoteTemplateRepository instance =
      SurgeryNoteTemplateRepository._();

  List<SurgeryNoteTemplate> getAll() => List.unmodifiable(
        mockSurgeryNoteTemplates.where(_isOwnedByCurrentUser),
      );

  SurgeryNoteTemplate? getById(String id) {
    for (final item in mockSurgeryNoteTemplates) {
      if (item.id == id && _isOwnedByCurrentUser(item)) return item;
    }
    return null;
  }

  List<SurgeryNoteTemplate> search(String query) {
    final q = query.trim().toLowerCase();
    final owned = getAll();
    if (q.isEmpty) return owned;
    return owned.where((t) {
      if (t.name.toLowerCase().contains(q)) return true;
      if (t.description.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  void add(SurgeryNoteTemplate template) =>
      mockSurgeryNoteTemplates.insert(0, template);

  void update(SurgeryNoteTemplate template) {
    final index = mockSurgeryNoteTemplates.indexWhere((t) => t.id == template.id);
    if (index >= 0) mockSurgeryNoteTemplates[index] = template;
  }

  bool delete(String id) {
    final index = mockSurgeryNoteTemplates.indexWhere((t) => t.id == id);
    if (index < 0) return false;
    mockSurgeryNoteTemplates.removeAt(index);
    return true;
  }

  bool _isOwnedByCurrentUser(SurgeryNoteTemplate template) {
    final profileId = SurgeryNoteOwnership.currentProfileId();
    if (profileId == null || profileId.isEmpty) return false;
    return template.profileId == profileId;
  }
}
