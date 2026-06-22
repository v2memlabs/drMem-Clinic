import 'consent_repository_failure.dart';
import 'consent_template_list_load_result.dart';
import 'consent_template_list_user_messages.dart';
import 'consent_template_repository_provider.dart';

abstract final class ConsentTemplateListDataSource {
  static Future<ConsentTemplateListLoadResult> load({
    required String query,
    String? categoryFilter,
    bool activeOnly = false,
  }) async {
    try {
      final templates =
          await ConsentTemplateRepositoryProvider.asyncRepository.getFiltered(
        query: query,
        categoryFilter: categoryFilter,
        activeOnly: activeOnly,
      );
      return ConsentTemplateListLoadResult.success(templates);
    } on ConsentRepositoryException catch (e) {
      return ConsentTemplateListLoadResult.failure(
        ConsentTemplateListUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ConsentTemplateListLoadResult.failure(
        ConsentTemplateListUserMessages.genericLoadFailure,
      );
    }
  }
}
