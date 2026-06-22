import '../models/imaging_note.dart';

abstract interface class AsyncImagingRepositoryContract {
  Future<List<ImagingNote>> getAll();

  Future<List<ImagingNote>> getByPatientId(String patientId);

  Future<ImagingNote?> getById(String id);

  Future<List<ImagingNote>> search(String query);

  Future<List<ImagingNote>> getFiltered({
    String? patientId,
    String? query,
    ImagingType? imagingTypeFilter,
    ImagingBodyRegion? bodyRegionFilter,
  });

  Future<ImagingNote> create(ImagingNote note);
}
