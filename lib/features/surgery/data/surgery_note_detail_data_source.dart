import '../models/surgery_procedure_note.dart';
import 'surgery_note_list_user_messages.dart';
import 'surgery_procedure_note_repository_failure.dart';
import 'surgery_procedure_note_repository_provider.dart';

class SurgeryNoteDetailLoadResult {
  final SurgeryProcedureNote? note;
  final String? errorMessage;

  const SurgeryNoteDetailLoadResult._({this.note, this.errorMessage});

  factory SurgeryNoteDetailLoadResult.success(SurgeryProcedureNote note) {
    return SurgeryNoteDetailLoadResult._(note: note);
  }

  factory SurgeryNoteDetailLoadResult.failure(String message) {
    return SurgeryNoteDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class SurgeryNoteDetailDataSource {
  static Future<SurgeryNoteDetailLoadResult> load(String id) async {
    try {
      final note =
          await SurgeryProcedureNoteRepositoryProvider.asyncRepository.getById(
        id,
      );
      if (note == null) {
        return SurgeryNoteDetailLoadResult.failure('Kayıt bulunamadı.');
      }
      return SurgeryNoteDetailLoadResult.success(note);
    } on SurgeryProcedureNoteRepositoryException catch (e) {
      return SurgeryNoteDetailLoadResult.failure(
        SurgeryNoteListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return SurgeryNoteDetailLoadResult.failure(
        SurgeryNoteListUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<String?> updateNotes({
    required String id,
    required String notes,
  }) async {
    try {
      await SurgeryProcedureNoteRepositoryProvider.asyncRepository.updateNotes(
        id,
        notes,
      );
      return null;
    } on SurgeryProcedureNoteRepositoryException catch (e) {
      return SurgeryNoteListUserMessages.forFailure(e.reason);
    } catch (_) {
      return 'Notlar kaydedilemedi.';
    }
  }
}
