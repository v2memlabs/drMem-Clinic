import '../../../core/data/repository_registry.dart';
import 'consent_detail_load_result.dart';
import 'consent_detail_user_messages.dart';
import 'consent_repository_failure.dart';

abstract final class ConsentDetailDataSource {
  static Future<ConsentDetailLoadResult> loadById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return ConsentDetailLoadResult.notFound();
    }

    try {
      final record = await RepositoryRegistry.consentsAsync.getById(trimmed);
      if (record == null) {
        return ConsentDetailLoadResult.notFound();
      }
      return ConsentDetailLoadResult.success(record);
    } on ConsentRepositoryException catch (e) {
      if (e.reason == ConsentRepositoryFailure.notFound) {
        return ConsentDetailLoadResult.notFound();
      }
      return ConsentDetailLoadResult.failure(
        ConsentDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ConsentDetailLoadResult.failure(
        ConsentDetailUserMessages.genericLoadFailure,
      );
    }
  }
}
