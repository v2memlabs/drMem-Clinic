import 'package:postgrest/postgrest.dart';

import 'clinical_report_repository_failure.dart';

abstract final class ClinicalReportRepositoryErrorMapper {
  static ClinicalReportRepositoryException toException(Object error) {
    if (error is ClinicalReportRepositoryException) return error;

    if (error is PostgrestException) {
      if (_isPermissionDenied(error)) {
        return const ClinicalReportRepositoryException(
          ClinicalReportRepositoryFailure.forbidden,
        );
      }
      if (error.code == 'PGRST116') {
        return const ClinicalReportRepositoryException(
          ClinicalReportRepositoryFailure.notFound,
        );
      }
      return const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.unknown,
      );
    }

    final message = error.toString().toLowerCase();
    if (message.contains('jwt') ||
        message.contains('permission') ||
        message.contains('forbidden') ||
        message.contains('42501')) {
      return const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.forbidden,
      );
    }
    if (message.contains('not found') || message.contains('pgrst116')) {
      return const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.notFound,
      );
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.network,
      );
    }
    if (message.contains('not configured') ||
        message.contains('supabase') && message.contains('init')) {
      return const ClinicalReportRepositoryException(
        ClinicalReportRepositoryFailure.notConfigured,
      );
    }
    return const ClinicalReportRepositoryException(
      ClinicalReportRepositoryFailure.unknown,
    );
  }

  static bool _isPermissionDenied(PostgrestException e) {
    final code = e.code ?? '';
    if (code == '42501') return true;
    final msg = e.message.toLowerCase();
    return msg.contains('permission') ||
        msg.contains('forbidden') ||
        msg.contains('row-level security');
  }
}
