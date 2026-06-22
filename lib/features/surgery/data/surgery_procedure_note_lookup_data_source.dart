import '../../../core/data/repository_registry.dart';
import '../models/surgery_procedure_note.dart';

/// Ameliyat / girişim notu okuma — [RepositoryRegistry.surgeryProcedureNotesAsync].
abstract final class SurgeryProcedureNoteLookupDataSource {
  static Future<SurgeryProcedureNote?> findById(String noteId) async {
    final id = noteId.trim();
    if (id.isEmpty) return null;

    try {
      return await RepositoryRegistry.surgeryProcedureNotesAsync.getById(id);
    } catch (_) {
      return null;
    }
  }

  static Future<List<SurgeryProcedureNote>> listByPatientId(String patientId) async {
    final pid = patientId.trim();
    if (pid.isEmpty) return const [];

    try {
      return await RepositoryRegistry.surgeryProcedureNotesAsync.getByPatientId(pid);
    } catch (_) {
      return const [];
    }
  }
}
