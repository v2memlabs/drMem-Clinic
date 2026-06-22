import '../models/imaging_note.dart';
import 'mock_imaging_notes.dart';

class ImagingRepository {
  ImagingRepository._();

  static final ImagingRepository instance = ImagingRepository._();

  List<ImagingNote> getAll() => List.unmodifiable(mockImagingNotes);

  ImagingNote? getById(String id) {
    for (final note in mockImagingNotes) {
      if (note.id == id) return note;
    }
    return null;
  }

  List<ImagingNote> getByPatientId(String patientId) =>
      mockImagingNotes.where((n) => n.patientId == patientId).toList();

  List<ImagingNote> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return mockImagingNotes.where((n) => _matchesQuery(n, q)).toList();
  }

  List<ImagingNote> getFiltered({
    String? patientId,
    String? query,
    ImagingType? imagingTypeFilter,
    ImagingBodyRegion? bodyRegionFilter,
  }) {
    Iterable<ImagingNote> list = mockImagingNotes;

    if (patientId != null && patientId.isNotEmpty) {
      list = list.where((n) => n.patientId == patientId);
    }
    if (imagingTypeFilter != null) {
      list = list.where((n) => n.imagingType == imagingTypeFilter);
    }
    if (bodyRegionFilter != null) {
      list = list.where((n) => n.bodyRegion == bodyRegionFilter);
    }

    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((n) => _matchesQuery(n, q));
    }

    return List<ImagingNote>.from(list);
  }

  void add(ImagingNote record) => mockImagingNotes.insert(0, record);

  static String regionLabel(ImagingBodyRegion region) {
    switch (region) {
      case ImagingBodyRegion.diz:
        return 'Diz';
      case ImagingBodyRegion.omuz:
        return 'Omuz';
      case ImagingBodyRegion.kalca:
        return 'Kalça';
      case ImagingBodyRegion.ayakBilegi:
        return 'Ayak Bileği';
      case ImagingBodyRegion.ayak:
        return 'Ayak';
      case ImagingBodyRegion.dirsek:
        return 'Dirsek';
      case ImagingBodyRegion.elBilegi:
        return 'El Bileği';
      case ImagingBodyRegion.el:
        return 'El';
      case ImagingBodyRegion.omurga:
        return 'Omurga';
      case ImagingBodyRegion.diger:
        return 'Diğer';
    }
  }

  static String typeLabel(ImagingType type) {
    switch (type) {
      case ImagingType.mr:
        return 'MR';
      case ImagingType.bt:
        return 'BT';
      case ImagingType.direktGrafi:
        return 'Direkt Grafi';
      case ImagingType.usg:
        return 'USG';
      case ImagingType.rapor:
        return 'Rapor';
      case ImagingType.diger:
        return 'Diğer';
    }
  }

  static bool matchesQuery(ImagingNote n, String q) {
    if (n.patientName.toLowerCase().contains(q)) return true;
    if (typeLabel(n.imagingType).toLowerCase().contains(q)) return true;
    if (n.imagingType.name.toLowerCase().contains(q)) return true;
    if (regionLabel(n.bodyRegion).toLowerCase().contains(q)) return true;
    if (n.bodyRegion.name.toLowerCase().contains(q)) return true;
    if (n.reportSummary.toLowerCase().contains(q)) return true;
    if (n.doctorComment.toLowerCase().contains(q)) return true;
    if (n.comparisonWithPrevious.toLowerCase().contains(q)) return true;
    if (n.relatedDiagnosis.toLowerCase().contains(q)) return true;
    if (n.imagingCenter.toLowerCase().contains(q)) return true;
    if ((n.attachedFileName ?? '').toLowerCase().contains(q)) return true;
    return false;
  }

  bool _matchesQuery(ImagingNote n, String q) => matchesQuery(n, q);
}
