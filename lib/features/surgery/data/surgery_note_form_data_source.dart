import '../models/surgery_procedure_note.dart';
import 'surgery_note_list_refresh.dart';
import 'surgery_note_list_user_messages.dart';
import 'surgery_note_ownership.dart';
import 'surgery_procedure_note_repository_failure.dart';
import 'surgery_procedure_note_repository_provider.dart';

abstract final class SurgeryNoteFormDataSource {
  static Future<SurgeryProcedureNote> create(SurgeryProcedureNote draft) async {
    try {
      final saved =
          await SurgeryProcedureNoteRepositoryProvider.asyncRepository.create(
        draft,
      );
      SurgeryNoteListRefresh.markStale();
      return saved;
    } on SurgeryProcedureNoteRepositoryException catch (e) {
      throw SurgeryNoteFormException(
        SurgeryNoteListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const SurgeryNoteFormException('Kayıt oluşturulamadı.');
    }
  }

  static Future<SurgeryProcedureNote> loadForEdit(String id) async {
    try {
      final note =
          await SurgeryProcedureNoteRepositoryProvider.asyncRepository.getById(
        id,
      );
      if (note == null) {
        throw const SurgeryNoteFormException('Ameliyat / girişim notu bulunamadı.');
      }
      if (!SurgeryNoteOwnership.canEditNote(note)) {
        throw const SurgeryNoteFormException('Bu notu düzenleme yetkiniz yok.');
      }
      return note;
    } on SurgeryNoteFormException {
      rethrow;
    } on SurgeryProcedureNoteRepositoryException catch (e) {
      throw SurgeryNoteFormException(
        SurgeryNoteListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const SurgeryNoteFormException('Kayıt yüklenemedi.');
    }
  }

  static Future<SurgeryProcedureNote> update(SurgeryProcedureNote note) async {
    if (!SurgeryNoteOwnership.canEditNote(note)) {
      throw const SurgeryNoteFormException('Bu notu düzenleme yetkiniz yok.');
    }

    try {
      final saved =
          await SurgeryProcedureNoteRepositoryProvider.asyncRepository.update(
        note,
      );
      SurgeryNoteListRefresh.markStale();
      return saved;
    } on SurgeryProcedureNoteRepositoryException catch (e) {
      throw SurgeryNoteFormException(
        SurgeryNoteListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const SurgeryNoteFormException('Kayıt güncellenemedi.');
    }
  }
}

class SurgeryNoteFormException implements Exception {
  final String message;

  const SurgeryNoteFormException(this.message);

  @override
  String toString() => message;
}
