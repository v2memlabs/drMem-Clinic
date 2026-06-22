import 'pdf_output_repository_failure.dart';

/// PostgREST / ağ hataları → [PdfOutputRepositoryException].
abstract final class PdfOutputRepositoryErrorMapper {
  static PdfOutputRepositoryException toException(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('42501') || message.contains('permission denied')) {
      return const PdfOutputRepositoryException(
        PdfOutputRepositoryFailure.forbidden,
      );
    }
    if (message.contains('pgrst116') || message.contains('0 rows')) {
      return const PdfOutputRepositoryException(
        PdfOutputRepositoryFailure.notFound,
      );
    }
    if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection')) {
      return const PdfOutputRepositoryException(
        PdfOutputRepositoryFailure.network,
      );
    }
    if (message.contains('yapılandır') || message.contains('configured')) {
      return const PdfOutputRepositoryException(
        PdfOutputRepositoryFailure.notConfigured,
      );
    }
    if (message.contains('aktif klinik') || message.contains('tenant')) {
      return const PdfOutputRepositoryException(
        PdfOutputRepositoryFailure.noActiveTenant,
      );
    }

    return PdfOutputRepositoryException(
      PdfOutputRepositoryFailure.unknown,
      cause: error,
    );
  }
}
