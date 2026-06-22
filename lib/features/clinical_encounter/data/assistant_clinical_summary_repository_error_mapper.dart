import 'package:postgrest/postgrest.dart';

import 'assistant_clinical_summary_repository_failure.dart';

/// Supabase/PostgREST hatalarını [AssistantClinicalSummaryRepositoryException]'a çevirir.
abstract final class AssistantClinicalSummaryRepositoryErrorMapper {
  static AssistantClinicalSummaryRepositoryException toException(Object error) {
    if (error is AssistantClinicalSummaryRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return AssistantClinicalSummaryRepositoryException(
          AssistantClinicalSummaryRepositoryFailure.forbidden,
          cause: error,
        );
      }
      if (error.code == '42501') {
        return AssistantClinicalSummaryRepositoryException(
          AssistantClinicalSummaryRepositoryFailure.forbidden,
          cause: error,
        );
      }
      return AssistantClinicalSummaryRepositoryException(
        AssistantClinicalSummaryRepositoryFailure.unknown,
        cause: error,
      );
    }

    if (_isNetworkError(error)) {
      return AssistantClinicalSummaryRepositoryException(
        AssistantClinicalSummaryRepositoryFailure.network,
        cause: error,
      );
    }

    return AssistantClinicalSummaryRepositoryException(
      AssistantClinicalSummaryRepositoryFailure.unknown,
      cause: error,
    );
  }

  static bool _isPermissionDenied(PostgrestException e) {
    final msg = e.message.toLowerCase();
    return msg.contains('permission') ||
        msg.contains('row-level security') ||
        msg.contains('rls');
  }

  static bool _isNetworkError(Object error) {
    final type = error.runtimeType.toString().toLowerCase();
    return type.contains('socket') ||
        type.contains('timeout') ||
        type.contains('clientexception');
  }
}
