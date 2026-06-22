import '../models/imaging_note.dart';
import 'imaging_repository_failure.dart';
import 'imaging_repository_provider.dart';
import 'imaging_user_messages.dart';

class ImagingListLoadResult {
  final List<ImagingNote> notes;
  final String? errorMessage;

  const ImagingListLoadResult._({
    this.notes = const [],
    this.errorMessage,
  });

  factory ImagingListLoadResult.success(List<ImagingNote> notes) {
    return ImagingListLoadResult._(notes: notes);
  }

  factory ImagingListLoadResult.failure(String message) {
    return ImagingListLoadResult._(errorMessage: message);
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}

abstract final class ImagingListDataSource {
  static Future<ImagingListLoadResult> load({
    String? patientId,
    String? query,
    ImagingType? imagingTypeFilter,
    ImagingBodyRegion? bodyRegionFilter,
  }) async {
    try {
      final notes = await ImagingRepositoryProvider.asyncRepository.getFiltered(
        patientId: patientId,
        query: query,
        imagingTypeFilter: imagingTypeFilter,
        bodyRegionFilter: bodyRegionFilter,
      );
      return ImagingListLoadResult.success(notes);
    } on ImagingRepositoryException catch (e) {
      return ImagingListLoadResult.failure(
        ImagingUserMessages.forFailure(e.reason),
      );
    } catch (_) {
      return ImagingListLoadResult.failure(
        ImagingUserMessages.genericLoadFailure,
      );
    }
  }
}
