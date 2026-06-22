import 'lab_order_template_list_load_result.dart';
import 'lab_order_template_repository_failure.dart';
import 'lab_order_template_repository_provider.dart';
import 'lab_order_template_user_messages.dart';

abstract final class LabOrderTemplateListDataSource {
  static Future<LabOrderTemplateListLoadResult> load({String? query}) async {
    try {
      final q = query?.trim() ?? '';
      final items = q.isEmpty
          ? await LabOrderTemplateRepositoryProvider.asyncRepository.getAll()
          : await LabOrderTemplateRepositoryProvider.asyncRepository.search(q);
      return LabOrderTemplateListLoadResult.success(items);
    } on LabOrderTemplateRepositoryException catch (e) {
      return LabOrderTemplateListLoadResult.failure(
        LabOrderTemplateUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return LabOrderTemplateListLoadResult.failure(
        LabOrderTemplateUserMessages.genericLoadFailure,
      );
    }
  }
}
