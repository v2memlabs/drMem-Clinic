import 'surgery_procedure_note_repository_failure.dart';

abstract final class SurgeryProcedureNoteRepositoryErrorMapper {
  static SurgeryProcedureNoteRepositoryException toException(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const SurgeryProcedureNoteRepositoryException(
        SurgeryProcedureNoteRepositoryFailure.notConfigured,
      );
    }
    return const SurgeryProcedureNoteRepositoryException(
      SurgeryProcedureNoteRepositoryFailure.unknown,
    );
  }
}
