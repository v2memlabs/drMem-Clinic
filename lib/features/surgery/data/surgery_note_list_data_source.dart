import '../models/surgery_procedure_note.dart';
import 'surgery_note_list_load_result.dart';
import 'surgery_note_list_user_messages.dart';
import 'surgery_procedure_note_repository_failure.dart';
import 'surgery_procedure_note_repository_provider.dart';
abstract final class SurgeryNoteListDataSource {
  static Future<SurgeryNoteListLoadResult> load({
    String? patientId,
    String? query,
    ProcedureType? procedureTypeFilter,
    SurgeryBodyRegion? bodyRegionFilter,
  }) async {
    try {
      final repo = SurgeryProcedureNoteRepositoryProvider.asyncRepository;
      final q = query?.trim() ?? '';
      final hasPatient = patientId != null && patientId.isNotEmpty;

      List<SurgeryProcedureNote> list;
      if (q.isNotEmpty) {
        list = await repo.search(q);
      } else if (hasPatient) {
        list = await repo.getByPatientId(patientId);
      } else {
        list = await repo.getAll();
      }

      if (procedureTypeFilter != null) {
        list = list.where((n) => n.procedureType == procedureTypeFilter).toList();
      }
      if (bodyRegionFilter != null) {
        list = list.where((n) => n.bodyRegion == bodyRegionFilter).toList();
      }

      list = List<SurgeryProcedureNote>.from(list);
      list.sort((a, b) {
        final byDate = b.procedureDate.compareTo(a.procedureDate);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

      return SurgeryNoteListLoadResult.success(list);
    } on SurgeryProcedureNoteRepositoryException catch (e) {
      return SurgeryNoteListLoadResult.failure(
        SurgeryNoteListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return SurgeryNoteListLoadResult.failure(
        SurgeryNoteListUserMessages.genericLoadFailure,
      );
    }
  }
}
