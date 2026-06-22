import '../models/imaging_note.dart';
import 'imaging_repository_failure.dart';
import 'imaging_repository_provider.dart';
import 'imaging_user_messages.dart';

class ImagingDetailLoadResult {
  final ImagingNote? note;
  final String? errorMessage;

  const ImagingDetailLoadResult._({this.note, this.errorMessage});

  factory ImagingDetailLoadResult.success(ImagingNote note) {
    return ImagingDetailLoadResult._(note: note);
  }

  factory ImagingDetailLoadResult.failure(String message) {
    return ImagingDetailLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class ImagingDetailDataSource {
  static Future<ImagingDetailLoadResult> load(String id) async {
    try {
      final note = await ImagingRepositoryProvider.asyncRepository.getById(id);
      if (note == null) {
        return ImagingDetailLoadResult.failure(ImagingUserMessages.notFound);
      }
      return ImagingDetailLoadResult.success(note);
    } on ImagingRepositoryException catch (e) {
      return ImagingDetailLoadResult.failure(
        ImagingUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ImagingDetailLoadResult.failure(
        ImagingUserMessages.genericLoadFailure,
      );
    }
  }
}
