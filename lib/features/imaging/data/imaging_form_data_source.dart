import '../models/imaging_note.dart';
import 'imaging_list_refresh.dart';
import 'imaging_repository_failure.dart';
import 'imaging_repository_provider.dart';
import 'imaging_user_messages.dart';

abstract final class ImagingFormDataSource {
  static Future<ImagingNote> create(ImagingNote draft) async {
    try {
      final saved = await ImagingRepositoryProvider.asyncRepository.create(draft);
      ImagingListRefresh.markStale();
      return saved;
    } on ImagingRepositoryException catch (e) {
      throw ImagingFormException(ImagingUserMessages.forFailure(e.reason));
    } catch (_) {
      throw const ImagingFormException(ImagingUserMessages.genericSaveFailure);
    }
  }
}

class ImagingFormException implements Exception {
  final String message;

  const ImagingFormException(this.message);

  @override
  String toString() => message;
}
