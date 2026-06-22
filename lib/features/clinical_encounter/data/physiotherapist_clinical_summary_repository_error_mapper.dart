import 'package:postgrest/postgrest.dart';

import 'physiotherapist_clinical_summary_repository_failure.dart';

/// Supabase/PostgREST hatalarını [PhysiotherapistClinicalSummaryRepositoryException]'a çevirir.
abstract final class PhysiotherapistClinicalSummaryRepositoryErrorMapper {
  static PhysiotherapistClinicalSummaryRepositoryException toException(
    Object error,
  ) {
    if (error is PhysiotherapistClinicalSummaryRepositoryException) {
      return error;
    }

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return PhysiotherapistClinicalSummaryRepositoryException(
          PhysiotherapistClinicalSummaryRepositoryFailure.forbidden,
          cause: error,
        );
      }
      if (error.code == '42501') {
        return PhysiotherapistClinicalSummaryRepositoryException(
          PhysiotherapistClinicalSummaryRepositoryFailure.forbidden,
          cause: error,
        );
      }
      return PhysiotherapistClinicalSummaryRepositoryException(
        PhysiotherapistClinicalSummaryRepositoryFailure.unknown,
        cause: error,
      );
    }

    if (_isNetworkError(error)) {
      return PhysiotherapistClinicalSummaryRepositoryException(
        PhysiotherapistClinicalSummaryRepositoryFailure.network,
        cause: error,
      );
    }

    return PhysiotherapistClinicalSummaryRepositoryException(
      PhysiotherapistClinicalSummaryRepositoryFailure.unknown,
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
