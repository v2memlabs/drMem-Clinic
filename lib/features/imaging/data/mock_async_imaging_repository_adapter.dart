import '../models/imaging_note.dart';
import 'async_imaging_repository_contract.dart';
import 'imaging_repository.dart';

class MockAsyncImagingRepositoryAdapter
    implements AsyncImagingRepositoryContract {
  ImagingRepository get _sync => ImagingRepository.instance;

  @override
  Future<ImagingNote> create(ImagingNote note) async {
    _sync.add(note);
    return note;
  }

  @override
  Future<List<ImagingNote>> getAll() async => _sync.getAll();

  @override
  Future<ImagingNote?> getById(String id) async => _sync.getById(id);

  @override
  Future<List<ImagingNote>> getByPatientId(String patientId) async =>
      _sync.getByPatientId(patientId);

  @override
  Future<List<ImagingNote>> getFiltered({
    String? patientId,
    String? query,
    ImagingType? imagingTypeFilter,
    ImagingBodyRegion? bodyRegionFilter,
  }) async {
    return _sync.getFiltered(
      patientId: patientId,
      query: query,
      imagingTypeFilter: imagingTypeFilter,
      bodyRegionFilter: bodyRegionFilter,
    );
  }

  @override
  Future<List<ImagingNote>> search(String query) async => _sync.search(query);
}
