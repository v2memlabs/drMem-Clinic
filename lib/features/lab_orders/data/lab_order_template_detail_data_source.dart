import '../models/lab_order_template.dart';
import 'lab_order_template_list_refresh.dart';
import 'lab_order_template_repository_failure.dart';
import 'lab_order_template_repository_provider.dart';
import 'lab_order_template_user_messages.dart';

class LabOrderTemplateDetailLoadResult {
  final LabOrderTemplate? template;
  final String? errorMessage;

  const LabOrderTemplateDetailLoadResult._({this.template, this.errorMessage});

  factory LabOrderTemplateDetailLoadResult.success(LabOrderTemplate template) {
    return LabOrderTemplateDetailLoadResult._(template: template);
  }

  factory LabOrderTemplateDetailLoadResult.failure(String message) {
    return LabOrderTemplateDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class LabOrderTemplateDetailDataSource {
  static Future<LabOrderTemplateDetailLoadResult> load(String id) async {
    try {
      final template =
          await LabOrderTemplateRepositoryProvider.asyncRepository.getById(id);
      if (template == null) {
        return LabOrderTemplateDetailLoadResult.failure(
          LabOrderTemplateUserMessages.notFound,
        );
      }
      return LabOrderTemplateDetailLoadResult.success(template);
    } on LabOrderTemplateRepositoryException catch (e) {
      return LabOrderTemplateDetailLoadResult.failure(
        LabOrderTemplateUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return LabOrderTemplateDetailLoadResult.failure(
        LabOrderTemplateUserMessages.genericLoadFailure,
      );
    }
  }

  static Future<String?> delete(String id) async {
    try {
      await LabOrderTemplateRepositoryProvider.asyncRepository.delete(id);
      LabOrderTemplateListRefresh.markStale();
      return null;
    } on LabOrderTemplateRepositoryException catch (e) {
      return LabOrderTemplateUserMessages.forFailure(e.reason);
    } catch (_) {
      return LabOrderTemplateUserMessages.genericDeleteFailure;
    }
  }
}
