import '../../../core/data/repository_registry.dart';
import 'physiotherapy_session_detail_load_result.dart';
import 'physiotherapy_session_repository_failure.dart';
import 'physiotherapy_session_user_messages.dart';

abstract final class PhysiotherapySessionDetailDataSource {
  static Future<PhysiotherapySessionDetailLoadResult> load(String id) async {
    try {
      final session =
          await RepositoryRegistry.physiotherapySessionsAsync.getById(id);
      if (session == null) {
        return PhysiotherapySessionDetailLoadResult.notFound();
      }
      return PhysiotherapySessionDetailLoadResult.success(session);
    } on PhysiotherapySessionRepositoryException catch (e) {
      return PhysiotherapySessionDetailLoadResult.failure(
        PhysiotherapySessionDetailUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return PhysiotherapySessionDetailLoadResult.failure(
        PhysiotherapySessionListUserMessages.genericLoadFailure,
      );
    }
  }
}
