import '../models/imaging_note.dart';
import 'async_imaging_repository_contract.dart';
import 'imaging_repository_failure.dart';

class SupabaseAsyncImagingRepositoryStub
    implements AsyncImagingRepositoryContract {
  const SupabaseAsyncImagingRepositoryStub();

  static const _error = ImagingRepositoryException(
    ImagingRepositoryFailure.notConfigured,
  );

  @override
  Future<ImagingNote> create(ImagingNote note) async => throw _error;

  @override
  Future<List<ImagingNote>> getAll() async => throw _error;

  @override
  Future<ImagingNote?> getById(String id) async => throw _error;

  @override
  Future<List<ImagingNote>> getByPatientId(String patientId) async =>
      throw _error;

  @override
  Future<List<ImagingNote>> getFiltered({
    String? patientId,
    String? query,
    ImagingType? imagingTypeFilter,
    ImagingBodyRegion? bodyRegionFilter,
  }) async =>
      throw _error;

  @override
  Future<List<ImagingNote>> search(String query) async => throw _error;
}
