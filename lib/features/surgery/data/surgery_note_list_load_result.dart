import '../models/surgery_procedure_note.dart';

class SurgeryNoteListLoadResult {
  final List<SurgeryProcedureNote> notes;
  final String? errorMessage;

  const SurgeryNoteListLoadResult._({
    required this.notes,
    this.errorMessage,
  });

  factory SurgeryNoteListLoadResult.success(List<SurgeryProcedureNote> notes) {
    return SurgeryNoteListLoadResult._(notes: notes);
  }

  factory SurgeryNoteListLoadResult.failure(String message) {
    return SurgeryNoteListLoadResult._(
      notes: const [],
      errorMessage: message,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
