import '../../../core/data/repository_registry.dart';
import '../models/imaging_note.dart';

/// Görüntüleme notu okuma — [RepositoryRegistry.imagingNotesAsync].
abstract final class ImagingLookupDataSource {
  static Future<ImagingNote?> findById(String imagingNoteId) async {
    final id = imagingNoteId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.imagingNotesAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<ImagingNote>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    try {
      return await RepositoryRegistry.imagingNotesAsync.getByPatientId(pid);
    } catch (_) {
      return const [];
    }
  }
}
