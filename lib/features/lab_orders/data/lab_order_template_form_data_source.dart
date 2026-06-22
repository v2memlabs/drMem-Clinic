import '../models/lab_order_template.dart';
import 'lab_order_template_list_refresh.dart';
import 'lab_order_template_repository_failure.dart';
import 'lab_order_template_repository_provider.dart';
import 'lab_order_template_user_messages.dart';

abstract final class LabOrderTemplateFormDataSource {
  static Future<LabOrderTemplate> create(LabOrderTemplate draft) async {
    try {
      final saved =
          await LabOrderTemplateRepositoryProvider.asyncRepository.create(
        draft,
      );
      LabOrderTemplateListRefresh.markStale();
      return saved;
    } on LabOrderTemplateRepositoryException catch (e) {
      throw LabOrderTemplateFormException(
        LabOrderTemplateUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const LabOrderTemplateFormException(
        LabOrderTemplateUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<LabOrderTemplate> update(LabOrderTemplate record) async {
    try {
      final saved =
          await LabOrderTemplateRepositoryProvider.asyncRepository.update(
        record,
      );
      LabOrderTemplateListRefresh.markStale();
      return saved;
    } on LabOrderTemplateRepositoryException catch (e) {
      throw LabOrderTemplateFormException(
        LabOrderTemplateUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      throw const LabOrderTemplateFormException(
        LabOrderTemplateUserMessages.genericSaveFailure,
      );
    }
  }

  static Future<LabOrderTemplate?> loadForEdit(String id) async {
    try {
      return await LabOrderTemplateRepositoryProvider.asyncRepository.getById(
        id,
      );
    } catch (_) {
      return null;
    }
  }
}

class LabOrderTemplateFormException implements Exception {
  final String message;

  const LabOrderTemplateFormException(this.message);

  @override
  String toString() => message;
}
