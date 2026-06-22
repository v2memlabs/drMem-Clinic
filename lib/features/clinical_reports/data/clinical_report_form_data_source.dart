import '../models/clinical_report.dart';
import 'clinical_report_list_refresh.dart';
import 'clinical_report_number_helper.dart';
import 'clinical_report_repository_failure.dart';
import 'clinical_report_repository_provider.dart';
import 'clinical_report_user_messages.dart';

abstract final class ClinicalReportFormDataSource {
  static Future<ClinicalReport> create(ClinicalReport draft) async {
    try {
      var toCreate = draft;
      if (draft.displayReportNumber == null) {
        final existing =
            await ClinicalReportRepositoryProvider.asyncRepository.getAll();
        toCreate = draft.copyWith(
          reportNumber: ClinicalReportNumberHelper.nextFromExisting(
            existing.map((r) => r.reportNumber ?? ''),
          ),
        );
      }

      final saved = await ClinicalReportRepositoryProvider.asyncRepository
          .create(toCreate);
      ClinicalReportListRefresh.markStale();
      return saved;
    } on ClinicalReportRepositoryException catch (e) {
      throw ClinicalReportFormException(
        ClinicalReportUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const ClinicalReportFormException(
        ClinicalReportUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<ClinicalReport> update(ClinicalReport record) async {
    try {
      final saved = await ClinicalReportRepositoryProvider.asyncRepository
          .update(record);
      ClinicalReportListRefresh.markStale();
      return saved;
    } on ClinicalReportRepositoryException catch (e) {
      throw ClinicalReportFormException(
        ClinicalReportUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const ClinicalReportFormException(
        ClinicalReportUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<ClinicalReport?> loadForEdit(String id) async {
    try {
      return await ClinicalReportRepositoryProvider.asyncRepository.getById(id);
    } catch (_) {
      return null;
    }
  }
}

class ClinicalReportFormException implements Exception {
  final String message;

  const ClinicalReportFormException(this.message);

  @override
  String toString() => message;
}
